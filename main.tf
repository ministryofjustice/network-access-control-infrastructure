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
    role_arn = local.assume_role
  }
}

data "aws_region" "current_region" {}
data "aws_caller_identity" "shared_services_account" {}


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
