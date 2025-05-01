locals {
  xaiam_secrets_version_development    = "2e73a1de-af34-4c1d-a8ce-759df5b7bf75"
  xaiam_secrets_version_pre_production = "9a071db2-4ed2-4c3f-9568-5ef2d5299dc4"
  xaiam_secrets_version_production     = "a275ae6e-fc4c-4341-bb63-064f4e2fe209"
}

#-----------------------------------------------------------------
### Getting the staff-device-shared-services-infrastructure state
#-----------------------------------------------------------------
data "terraform_remote_state" "staff-device-shared-services-infrastructure" {
  backend = "s3"

  config = {
    bucket = "pttp-global-bootstrap-pttp-infrastructure-tf-remote-state"
    key    = "env:/ci/terraform/v1/state"
    region = "eu-west-2"
  }
}

#-----------------------------------------------------------------
### Getting secrets from secrets manager
#-----------------------------------------------------------------

data "aws_secretsmanager_secret" "xsiam_endpoint_secrets" {
  name = "/nac-server/${terraform.workspace}/xsiam_endpoint_secrets"
}

data "aws_secretsmanager_secret_version" "xaiam_secrets_version" {
  secret_id  = data.aws_secretsmanager_secret.xsiam_endpoint_secrets.id
  version_id = terraform.workspace == "pre-production" ? local.xaiam_secrets_version_pre_production : terraform.workspace == "production" ? local.xaiam_secrets_version_production : local.xaiam_secrets_version_development
}

data "aws_secretsmanager_secret" "allowed_ips" {
  name = "/moj-network-access-control/production/allowed_ips"
}

data "aws_secretsmanager_secret_version" "allowed_ips" {
  secret_id = data.aws_secretsmanager_secret.allowed_ips.id
}

#-----------------------------------------------------------------
### Getting parameters from ssm param store
#-----------------------------------------------------------------

data "aws_ssm_parameter" "shared_services_account_id" {
  name = "/codebuild/staff_device_shared_services_account_id"
}

data "aws_ssm_parameter" "assume_role" {
  name = "/codebuild/pttp-ci-infrastructure-core-pipeline/${terraform.workspace}/assume_role"
}

data "aws_ssm_parameter" "azure_federation_metadata_url" {
  name = "/moj-network-access-control/${terraform.workspace}/azure_federation_metadata_url"
}

data "aws_ssm_parameter" "hosted_zone_domain" {
  name = "/moj-network-access-control/${terraform.workspace}/hosted_zone_domain"
}

data "aws_ssm_parameter" "hosted_zone_id" {
  name = "/moj-network-access-control/${terraform.workspace}/hosted_zone_id"
}

data "aws_ssm_parameter" "admin_db_username" {
  name = "/moj-network-access-control/${terraform.workspace}/admin_db_username"
}

data "aws_ssm_parameter" "admin_db_password" {
  name = "/moj-network-access-control/${terraform.workspace}/admin_db_password"
}

data "aws_ssm_parameter" "admin_sentry_dsn" {
  name = "/moj-network-access-control/${terraform.workspace}/admin_sentry_dsn"
}

data "aws_ssm_parameter" "transit_gateway_id" {
  name = "/moj-network-access-control/${terraform.workspace}/transit_gateway_id"
}

data "aws_ssm_parameter" "transit_gateway_route_table_id" {
  name = "/moj-network-access-control/${terraform.workspace}/transit_gateway_route_table_id"
}

data "aws_ssm_parameter" "mojo_dns_ip_1" {
  name = "/moj-network-access-control/${terraform.workspace}/mojo_dns_ip_1"
}

data "aws_ssm_parameter" "mojo_dns_ip_2" {
  name = "/moj-network-access-control/${terraform.workspace}/mojo_dns_ip_2"
}

data "aws_ssm_parameter" "ocsp_endpoint_ip" {
  name = "/moj-network-access-control/${terraform.workspace}/ocsp/endpoint_ip"
}

data "aws_ssm_parameter" "ocsp_endpoint_port" {
  name = "/moj-network-access-control/${terraform.workspace}/ocsp/endpoint_port"
}

data "aws_ssm_parameter" "ocsp_atos_domain" {
  name = "/moj-network-access-control/${terraform.workspace}/ocsp/atos/domain"
}

data "aws_ssm_parameter" "cidr_range_1" {
  name = "/moj-network-access-control/${terraform.workspace}/ocsp/atos/cidr_range_1"
}

data "aws_ssm_parameter" "cidr_range_2" {
  name = "/moj-network-access-control/${terraform.workspace}/ocsp/atos/cidr_range_2"
}

data "aws_ssm_parameter" "enable_ocsp" {
  name = "/moj-network-access-control/${terraform.workspace}/enable_ocsp"
}

data "aws_ssm_parameter" "ocsp_override_cert_url" {
  name = "/moj-network-access-control/${terraform.workspace}/ocsp_override_cert_url"
}

data "aws_ssm_parameter" "byoip_pool_id" {
  name = "/moj-network-access-control/${terraform.workspace}/public_ip_pool_id"
}

data "aws_ssm_parameter" "eap_private_key_password" {
  name = "/moj-network-access-control/${terraform.workspace}/eap_private_key_password"
}

data "aws_ssm_parameter" "radsec_private_key_password" {
  name = "/moj-network-access-control/${terraform.workspace}/radsec_private_key_password"
}

data "aws_ssm_parameter" "enable_packet_capture" {
  name = "/moj-network-access-control/${terraform.workspace}/debug/radius/enable_packet_capture"
}

data "aws_ssm_parameter" "packet_capture_duration_seconds" {
  name = "/moj-network-access-control/${terraform.workspace}/debug/radius/packet_capture_duration_seconds"
}

data "aws_ssm_parameter" "cloudwatch_link" {
  name = "/moj-network-access-control/${terraform.workspace}/cloudwatch_link"
}

data "aws_ssm_parameter" "grafana_dashboard_link" {
  name = "/moj-network-access-control/${terraform.workspace}/grafana_dashboard_link"
}

data "aws_ssm_parameter" "enable_rds_admin_bastion" {
  name = "/moj-network-access-control/${terraform.workspace}/enable_rds_admin_bastion"
}

data "aws_ssm_parameter" "enable_rds_servers_bastion" {
  name = "/moj-network-access-control/${terraform.workspace}/enable_rds_servers_bastion"
}

data "aws_ssm_parameter" "ocsp_dep_ip" {
  name = "/moj-network-access-control/${terraform.workspace}/ocsp_dep_ip"
}

data "aws_ssm_parameter" "ocsp_prs_ip" {
  name = "/moj-network-access-control/${terraform.workspace}/ocsp_prs_ip"
}

data "aws_ssm_parameter" "ocsp_dhl_ip" {
  name = "/moj-network-access-control/${terraform.workspace}/ocsp_dhl_ip"
}

data "aws_ssm_parameter" "ocsp_dhl_failover_ip" {
  name = "/moj-network-access-control/${terraform.workspace}/ocsp_dhl_failover_ip"
}

data "aws_ssm_parameter" "ocsp_nhs_oxleas_ip" {
  name = "/moj-network-access-control/${terraform.workspace}/ocsp_nhs_oxleas_ip"
}
