locals {

  ## for resources which requires the tags map without the "Name" value
  ## It uses the "name" attribute internally and concatenates with other attributes
  tags_minus_name = { for k, v in module.label.tags : k => v if !contains(["Name"], k) }

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

  assume_role                     = data.aws_ssm_parameter.assume_role.value
  azure_federation_metadata_url   = data.aws_ssm_parameter.azure_federation_metadata_url.value
  hosted_zone_domain              = nonsensitive(data.aws_ssm_parameter.hosted_zone_domain.value)
  hosted_zone_id                  = nonsensitive(data.aws_ssm_parameter.hosted_zone_id.value)
  admin_db_username               = data.aws_ssm_parameter.admin_db_username.value
  admin_db_password               = data.aws_ssm_parameter.admin_db_password.value
  admin_sentry_dsn                = data.aws_ssm_parameter.admin_sentry_dsn.value
  transit_gateway_id              = nonsensitive(data.aws_ssm_parameter.transit_gateway_id.value)
  transit_gateway_route_table_id  = nonsensitive(data.aws_ssm_parameter.transit_gateway_route_table_id.value)
  mojo_dns_ip_1                   = nonsensitive(data.aws_ssm_parameter.mojo_dns_ip_1.value)
  mojo_dns_ip_2                   = nonsensitive(data.aws_ssm_parameter.mojo_dns_ip_2.value)
  ocsp_atos_domain                = data.aws_ssm_parameter.ocsp_atos_domain.value
  ocsp_atos_cidr_range_1          = nonsensitive(data.aws_ssm_parameter.cidr_range_1.value)
  ocsp_atos_cidr_range_2          = nonsensitive(data.aws_ssm_parameter.cidr_range_2.value)
  ocsp_endpoint_ip                = data.aws_ssm_parameter.ocsp_endpoint_ip.value
  ocsp_endpoint_port              = data.aws_ssm_parameter.ocsp_endpoint_port.value
  ocsp_dep_ip                     = nonsensitive(data.aws_ssm_parameter.ocsp_dep_ip.value)
  ocsp_prs_ip                     = nonsensitive(data.aws_ssm_parameter.ocsp_prs_ip.value)
  ocsp_dhl_ip                     = nonsensitive(data.aws_ssm_parameter.ocsp_dhl_ip.value)
  ocsp_dhl_failover_ip            = nonsensitive(data.aws_ssm_parameter.ocsp_dhl_failover_ip.value)
  ocsp_nhs_oxleas_ip              = nonsensitive(data.aws_ssm_parameter.ocsp_nhs_oxleas_ip.value)
  enable_ocsp                     = data.aws_ssm_parameter.enable_ocsp.value
  ocsp_override_cert_url          = data.aws_ssm_parameter.ocsp_override_cert_url.value
  byoip_pool_id                   = nonsensitive(data.aws_ssm_parameter.byoip_pool_id.value)
  eap_private_key_password        = data.aws_ssm_parameter.eap_private_key_password.value
  radsec_private_key_password     = data.aws_ssm_parameter.radsec_private_key_password.value
  radius_enable_packet_capture    = tobool(data.aws_ssm_parameter.enable_packet_capture.value)
  packet_capture_duration_seconds = data.aws_ssm_parameter.packet_capture_duration_seconds.value
  cloudwatch_link                 = data.aws_ssm_parameter.cloudwatch_link.value
  grafana_dashboard_link          = data.aws_ssm_parameter.grafana_dashboard_link.value
  enable_rds_servers_bastion      = tobool(data.aws_ssm_parameter.enable_rds_servers_bastion.value)
  enable_rds_admin_bastion        = tobool(data.aws_ssm_parameter.enable_rds_admin_bastion.value)
  shared_services_account_id      = data.aws_ssm_parameter.shared_services_account_id.value
}
