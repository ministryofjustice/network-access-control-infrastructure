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
  eap_private_key_password        = var.eap_private_key_password
  radsec_private_key_password     = var.radsec_private_key_password
  mojo_dns_ip_1                   = var.mojo_dns_ip_1
  mojo_dns_ip_2                   = var.mojo_dns_ip_2
  ocsp_atos_domain                = var.ocsp_atos_domain
  enable_ocsp_dns_resolver        = local.is_production
  vpc_flow_logs_group_id          = module.radius_vpc_flow_logs.flow_log_group_id
  log_metrics_namespace           = local.is_local_development ? "${module.label.id}-mojo-nac-requests" : "mojo-nac-requests"
  shared_services_account_id      = var.shared_services_account_id
  allowed_ips                     = jsondecode(data.aws_secretsmanager_secret_version.allowed_ips.secret_string)["allowed_ips"]


  read_replica = {
    name = module.admin_read_replica.rds.name
    host = module.admin_read_replica.rds.host
    user = var.admin_db_username
    pass = var.admin_db_password
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



module "admin_read_replica" {
  source                          = "./modules/admin_read_replica"
  replication_source              = module.admin.rds.admin_db_arn
  subnet_ids                      = module.radius_vpc.private_subnets
  rds_monitoring_role             = module.admin.rds.rds_monitoring_role
  vpc_id                          = module.radius_vpc.vpc_id
  db_password                     = var.admin_db_password
  db_size                         = "db.t3.large"
  radius_server_security_group_id = module.radius.ec2.radius_server_security_group_id
  prefix                          = "${module.label.id}-admin-read-replica"
  tags                            = module.label.tags

  providers = {
    aws = aws.env
  }
}





data "aws_region" "current_region" {}
data "aws_caller_identity" "shared_services_account" {}
