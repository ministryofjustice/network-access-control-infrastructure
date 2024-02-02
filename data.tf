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

data "aws_secretsmanager_secret" "xsiam_endpoint_secrets" {
  name = "/nac-server/${terraform.workspace}/xsiam_endpoint_secrets"
}

data "aws_secretsmanager_secret_version" "xaiam_secrets_version" {
  secret_id  = data.aws_secretsmanager_secret.xsiam_endpoint_secrets.id
  version_id = terraform.workspace == "pre-production" ? local.xaiam_secrets_version_pre_production : terraform.workspace == "production" ? local.xaiam_secrets_version_production : local.xaiam_secrets_version_development
}
