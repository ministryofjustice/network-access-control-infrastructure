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
    #user = var.admin_db_username
    #pass = var.admin_db_password
    user = jsondecode(data.aws_secretsmanager_secret_version.moj_network_access_control_env_admin_db.secret_string)["username"]
    pass = jsondecode(data.aws_secretsmanager_secret_version.moj_network_access_control_env_admin_db.secret_string)["password"]
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
