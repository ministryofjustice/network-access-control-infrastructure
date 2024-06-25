terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = "eu-west-2"
}

module "label" {
  source  = "cloudposse/label/null"
  version = "0.24.1"

  delimiter = "-"
  namespace = "mojo"
  stage     = "bootstrap"
  name      = "nac-infrastructure"

  tags = {
    "business-unit"    = "MoJO"
    "environment-name" = "global"
    "owner"            = var.owner_email
    "is-production"    = tostring(var.is_production)
    "application"      = "network-access-control-infrastructure"
    "source-code"      = "https://github.com/ministryofjustice/network-access-control-infrastructure"
  }
}
