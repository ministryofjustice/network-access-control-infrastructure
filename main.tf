terraform {
  backend "s3" {
    bucket         = "pttp-ci-infrastructure-nac-client-core-tf-state"
    dynamodb_table = "pttp-ci-infrastructure-nac-client-core-tf-lock-table"
    region         = "eu-west-2"
  }
}

provider "aws" {
  region = "eu-west-2"
  alias  = "env"
  assume_role {
    role_arn = var.assume_role
  }
}

module "label" {
  source  = "cloudposse/label/null"
  version = "0.25.0"

  delimiter = "-"
  namespace = "mojo"
  stage     = terraform.workspace
  name      = var.service_name

  tags = {
    "business-unit"    = "HQ"
    "application"      = "network-access-control"
    "is-production"    = tostring(local.is_production)
    "owner"            = "nac@digital.justice.gov.uk"
    "environment-name" = "global"
    "source-code"      = "https://github.com/ministryofjustice/network-access-control-infrastructure"
  }
}


locals {
  private_ip_eu_west_2a   = "10.180.108.10"
  private_ip_eu_west_2b   = "10.180.109.10"
  private_ip_eu_west_2c   = "10.180.110.10"
  vpc_cidr                = "10.180.108.0/22"
  is_production           = terraform.workspace == "production" ? true : false
  is_pre_production       = terraform.workspace == "pre-production" ? true : false
  is_development          = terraform.workspace == "development" ? true : false
  is_local_development    = !local.is_development && !local.is_pre_production && !local.is_production
  run_restore_from_backup = false

  s3-mojo_file_transfer_assume_role_arn = data.terraform_remote_state.staff-device-shared-services-infrastructure.outputs.s3-mojo_file_transfer_assume_role_arn
}

module "radius" {
  source                          = "./modules/radius"
  prefix                          = module.label.id
  short_prefix                    = module.label.stage
  env                             = module.label.stage
  byoip_pool_id                   = var.byoip_pool_id
  ocsp_endpoint_ip                = var.ocsp_endpoint_ip
  ocsp_endpoint_port              = var.ocsp_endpoint_port
  ocsp_override_cert_url          = var.ocsp_override_cert_url
  enable_ocsp                     = var.enable_ocsp
  enable_nlb_deletion_protection  = local.is_production ? true : false
  enable_hosted_zone              = var.enable_hosted_zone
  hosted_zone_domain              = var.hosted_zone_domain
  hosted_zone_id                  = var.hosted_zone_id
  packet_capture_duration_seconds = var.packet_capture_duration_seconds
  enable_packet_capture           = var.radius_enable_packet_capture
  tags                            = module.label.tags
  eap_private_key_password        = data.aws_secretsmanager_secret_version.moj_network_access_control_env_eap_private_key_password.secret_string
  radsec_private_key_password     = data.aws_secretsmanager_secret_version.moj_network_access_control_env_radsec_private_key_password.secret_string
  mojo_dns_ip_1                   = var.mojo_dns_ip_1
  mojo_dns_ip_2                   = var.mojo_dns_ip_2
  ocsp_atos_domain                = var.ocsp_atos_domain
  enable_ocsp_dns_resolver        = local.is_production
  vpc_flow_logs_group_id          = module.radius_vpc_flow_logs.flow_log_group_id
  log_metrics_namespace           = local.is_local_development ? "${module.label.id}-mojo-nac-requests" : "mojo-nac-requests"
  shared_services_account_id      = var.shared_services_account_id
  allowed_ips                     = jsondecode(data.aws_secretsmanager_secret_version.allowed_ips.secret_string)["allowed_ips"]
  secret_arns                     = local.secret_manager_arns


  read_replica = {
    name = module.admin_read_replica.rds.name
    host = module.admin_read_replica.rds.host
    user = var.admin_db_username
    pass = var.admin_db_password
    #user = jsondecode(data.aws_secretsmanager_secret_version.moj_network_access_control_env_admin_db.secret_string)["username"]
    #pass = jsondecode(data.aws_secretsmanager_secret_version.moj_network_access_control_env_admin_db.secret_string)["password"]
  }

  vpc = {
    cidr                  = local.vpc_cidr
    id                    = module.radius_vpc.vpc_id
    private_ip_eu_west_2a = local.private_ip_eu_west_2a
    private_ip_eu_west_2b = local.private_ip_eu_west_2b
    private_ip_eu_west_2c = local.private_ip_eu_west_2c
    private_subnets       = module.radius_vpc.private_subnets
    public_subnets        = module.radius_vpc.public_subnets
  }

  local_development_domain_affix = var.local_development_domain_affix
  read_replica_security_group_id = module.admin_read_replica.rds.security_group_id

  log_filters = [
    "Sent Access-Accept",
    "Sent Access-Reject",
    "Ignoring request to auth proto tcp address",
    "Ignoring request to auth address",
    "Error: post_auth - Failed to find attribute",
    "Error: python",
    "Shared secret is incorrect",
    "unknown CA",
    "authorized_macs: users: Matched entry",
    "Health Check: OK",
    "Failed to start task",
    "?'error' ?'Error' ?'ERROR'",
    "Certificate Expiry Warning:",
    "reject Wireless-802.11",
    "reject Ethernet"
  ]

  providers = {
    aws = aws.env
  }
}

module "ecs_auto_scaling_radius_public" {
  source                   = "./modules/ecs_auto_scaling_radius"
  prefix                   = module.label.id
  service_name             = module.radius.ecs.service_name
  cluster_name             = module.radius.ecs.cluster_name
  load_balancer_arn_suffix = module.radius.ec2.load_balancer_arn_suffix
  tags                     = module.label.tags
  providers = {
    aws = aws.env
  }
}

module "ecs_auto_scaling_radius_internal" {
  source                   = "./modules/ecs_auto_scaling_radius"
  prefix                   = "${module.label.id}-internal"
  service_name             = module.radius.ecs.internal_service_name
  cluster_name             = module.radius.ecs.cluster_name
  load_balancer_arn_suffix = module.radius.ec2.internal_load_balancer_arn_suffix
  tags                     = module.label.tags
  providers = {
    aws = aws.env
  }
}

module "radius_vpc" {
  source                                = "./modules/vpc"
  prefix                                = module.label.id
  region                                = data.aws_region.current_region.id
  cidr_block                            = local.vpc_cidr
  enable_nac_transit_gateway_attachment = var.enable_nac_transit_gateway_attachment
  transit_gateway_id                    = var.transit_gateway_id
  transit_gateway_route_table_id        = var.transit_gateway_route_table_id
  mojo_dns_ip_1                         = var.mojo_dns_ip_1
  mojo_dns_ip_2                         = var.mojo_dns_ip_2
  ocsp_endpoint_ip                      = var.ocsp_endpoint_ip
  ocsp_atos_cidr_range_1                = var.ocsp_atos_cidr_range_1
  ocsp_atos_cidr_range_2                = var.ocsp_atos_cidr_range_2
  tags                                  = module.label.tags
  ssm_session_manager_endpoints         = var.enable_rds_servers_bastion
  ocsp_dep_ip                           = var.ocsp_dep_ip
  ocsp_prs_ip                           = var.ocsp_prs_ip

  providers = {
    aws = aws.env
  }
}

module "radius_vpc_flow_logs" {
  source = "./modules/vpc_flow_logs"
  prefix = module.label.id
  region = "eu-west-2"
  vpc_id = module.radius_vpc.vpc_id
  tags   = module.label.tags

  providers = {
    aws = aws.env
  }
}

module "admin_read_replica" {
  source                          = "./modules/admin_read_replica"
  replication_source              = module.admin.rds.admin_db_arn
  subnet_ids                      = module.radius_vpc.private_subnets
  rds_monitoring_role             = module.admin.rds.rds_monitoring_role
  vpc_id                          = module.radius_vpc.vpc_id
  db_password                     = jsondecode(data.aws_secretsmanager_secret_version.moj_network_access_control_env_admin_db.secret_string)["password"]
  db_size                         = "db.t3.large"
  radius_server_security_group_id = module.radius.ec2.radius_server_security_group_id
  prefix                          = "${module.label.id}-admin-read-replica"
  tags                            = module.label.tags

  providers = {
    aws = aws.env
  }
}

module "admin" {
  source                            = "./modules/admin"
  prefix                            = "${module.label.id}-admin"
  short_prefix                      = module.label.stage # avoid 32 char limit on certain resources
  tags                              = module.label.tags
  run_restore_from_backup           = local.run_restore_from_backup
  sentry_dsn                        = data.aws_secretsmanager_secret_version.moj_network_access_control_env_admin_sentry_dsn.secret_string
  secret_key_base                   = "tbc"
  radius_certificate_bucket_arn     = module.radius.s3.radius_certificate_bucket_arn
  radius_certificate_bucket_name    = module.radius.s3.radius_certificate_bucket_name
  radius_config_bucket_name         = module.radius.s3.radius_config_bucket_name
  radius_config_bucket_arn          = module.radius.s3.radius_config_bucket_arn
  radius_config_bucket_key_arn      = module.radius.s3.radius_config_bucket_key_arn
  radius_certificate_bucket_key_arn = module.radius.s3.radius_certificate_bucket_key_arn
  region                            = data.aws_region.current_region.id
  hosted_zone_id                    = var.hosted_zone_id
  hosted_zone_domain                = var.hosted_zone_domain
  radius_cluster_name               = module.radius.ecs.cluster_name
  radius_cluster_id                 = module.radius.ecs.cluster_id
  radius_service_name               = module.radius.ecs.service_name
  radius_internal_service_name      = module.radius.ecs.internal_service_name
  radius_service_arn                = module.radius.ecs.service_arn
  radius_internal_service_arn       = module.radius.ecs.internal_service_arn
  cognito_user_pool_id              = module.authentication.cognito_user_pool_id
  cognito_user_pool_domain          = module.authentication.cognito_user_pool_domain
  cognito_user_pool_client_id       = module.authentication.cognito_user_pool_client_id
  cognito_user_pool_client_secret   = module.authentication.cognito_user_pool_client_secret
  local_development_domain_affix    = var.local_development_domain_affix
  cloudwatch_link                   = var.cloudwatch_link
  grafana_dashboard_link            = var.grafana_dashboard_link
  eap_private_key_password          = data.aws_secretsmanager_secret_version.moj_network_access_control_env_eap_private_key_password.secret_string
  radsec_private_key_password       = data.aws_secretsmanager_secret_version.moj_network_access_control_env_radsec_private_key_password.secret_string
  shared_services_account_id        = var.shared_services_account_id
  secret_arns                       = local.secret_manager_arns
  server_ips = join(", ", [
    module.radius.load_balancer.nac_eu_west_2a_ip_address,
    module.radius.load_balancer.nac_eu_west_2b_ip_address,
    module.radius.load_balancer.nac_eu_west_2c_ip_address
  ])

  db = {
    apply_updates_immediately = local.is_production ? false : true
    backup_retention_period   = var.admin_db_backup_retention_period
    delete_automated_backups  = local.is_production ? false : true
    deletion_protection       = local.is_production ? true : false
    #password                  = jsondecode(data.aws_secretsmanager_secret_version.moj_network_access_control_env_admin_db.secret_string)["password"]
    skip_final_snapshot       = true
    #username                  = jsondecode(data.aws_secretsmanager_secret_version.moj_network_access_control_env_admin_db.secret_string)["username"]
    username = var.admin_db_username
    password = var.admin_db_password

  }

  vpc = {
    id              = module.admin_vpc.vpc_id
    public_subnets  = module.admin_vpc.public_subnets
    private_subnets = module.admin_vpc.private_subnets
  }

  depends_on = [
    module.admin_vpc
  ]

  providers = {
    aws = aws.env
  }
}

module "authentication" {
  source                        = "./modules/cognito"
  azure_federation_metadata_url = var.azure_federation_metadata_url
  prefix                        = module.label.id
  enable_authentication         = var.enable_authentication
  admin_url                     = module.admin.admin_url
  region                        = data.aws_region.current_region.id
  hosted_zone_domain            = var.hosted_zone_domain

  providers = {
    aws = aws.env
  }
}

data "aws_region" "current_region" {}
data "aws_caller_identity" "shared_services_account" {}

module "admin_vpc" {
  source                        = "./modules/admin_vpc"
  prefix                        = "${module.label.id}-admin"
  region                        = data.aws_region.current_region.id
  cidr_block                    = "10.0.0.0/16"
  tags                          = module.label.tags
  ssm_session_manager_endpoints = var.enable_rds_admin_bastion

  providers = {
    aws = aws.env
  }
}

module "admin_vpc_flow_logs" {
  source = "./modules/vpc_flow_logs"
  prefix = "${module.label.id}-admin-vpc-flow-logs"
  region = data.aws_region.current_region.id
  tags   = module.label.tags
  vpc_id = module.admin_vpc.vpc_id

  providers = {
    aws = aws.env
  }
}

module "performance_testing" {
  source                   = "./modules/performance_testing"
  count                    = local.is_development ? 1 : 0
  prefix                   = "${module.label.id}-perf"
  vpc_id                   = module.radius_vpc.vpc_id
  subnets                  = module.radius_vpc.public_subnets
  load_balancer_ip_address = module.radius.load_balancer.nac_eu_west_2a_ip_address

  providers = {
    aws = aws.env
  }
}

module "kinesis_firehose_xsiam" {
  source                                = "./modules/kinesis_firehose_xsiam"
  http_endpoint                         = jsondecode(data.aws_secretsmanager_secret_version.xaiam_secrets_version.secret_string)["http_endpoint"]
  access_key                            = jsondecode(data.aws_secretsmanager_secret_version.xaiam_secrets_version.secret_string)["access_key"]
  prefix                                = "${module.label.id}-xsiam"
  tags                                  = module.label.tags
  cloudwatch_log_group_for_subscription = module.radius.cloudwatch.server_log_group_name

  providers = {
    aws = aws.env
  }
}
