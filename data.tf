locals {
  xaiam_secrets_version_development    = "74b8d013-7096-415b-a8f4-20adc4624667"
  xaiam_secrets_version_pre_production = "f0bd19d9-9e31-478f-a483-6cb010ca58a0"
  xaiam_secrets_version_production     = "ee71326d-aa17-4035-98cb-19ac8bee3b47"
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

data "aws_secretsmanager_secret" "xsiam_endpoint_secrets" {
  name = "/nac-server/${terraform.workspace}/xsiam_endpoint_secrets"
}

data "aws_secretsmanager_secret_version" "xaiam_secrets_version" {
  secret_id  = data.aws_secretsmanager_secret.xsiam_endpoint_secrets.id
  version_id = terraform.workspace == "pre-production" ? local.xaiam_secrets_version_pre_production : terraform.workspace == "production" ? local.xaiam_secrets_version_production : local.xaiam_secrets_version_development
}
