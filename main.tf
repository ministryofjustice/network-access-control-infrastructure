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











data "aws_region" "current_region" {}
data "aws_caller_identity" "shared_services_account" {}
