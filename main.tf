terraform {
  backend "s3" {
    bucket = "mojo-bootstrap-nac-infrastructure-terraform-remote-state"
    dynamodb_table = "mojo-bootstrap-nac-infrastructure-terraform-remote-state-lock-dynamo"
    key    = "terraform/v1/state"
    region = "eu-west-2"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

module "label" {
  source  = "cloudposse/label/null"
  version = "0.24.1"

  delimiter = "-"
  namespace = "mojo"
  stage     = terraform.workspace
  name      = var.service_name

  tags = {
    "business-unit" = "MoJO"
    "application"   = "nac",
    "is-production" = "true"
    "owner"         = "nac@digital.justice.gov.uk"
    "environment-name" = "global"
    "source-code"      = "https://github.com/ministryofjustice/network-access-control-infrastructure"
  }
}


locals {
  private_ip_eu_west_2a = "10.0.0.7"
  private_ip_eu_west_2b = "10.0.1.6"
  vpc_cidr = "10.0.0.0/16"
  client_vpc_cidr = "192.168.0.0/16"
}

provider "aws" {
  region = "eu-west-2"
}

module "radius" {
  source  = "./modules/radius"
  prefix = module.label.id
  vpc_id = module.radius_vpc.vpc_id
  private_ip_eu_west_2a = local.private_ip_eu_west_2a
  private_ip_eu_west_2b = local.private_ip_eu_west_2b
  public_subnets = module.radius_vpc.public_subnets
  private_subnets = module.radius_vpc.private_subnets
  vpc_cidr = local.vpc_cidr
  radius_db_username = var.radius_db_username
  radius_db_password = var.radius_db_password
  log_filters = [
    "Accept",
    "Reject",
    "did not finish"
  ]
}

module "radius_vpc" {
  source  = "./modules/vpc"
  prefix = module.label.id
  cidr_block = local.vpc_cidr
}

module "radius_client_vpc" {
  source  = "./modules/vpc"
  prefix = module.label.id
  cidr_block = local.client_vpc_cidr
}

module "radius_vpc_flow_logs" {
  source = "./modules/vpc_flow_logs"
  prefix = module.label.id
  region = "eu-west-2"
  vpc_id = module.radius_vpc.vpc_id
}

module "vpc_peering_internal_authentication" {
  source = "./modules/vpc_peering_internal_authentication"
  target_aws_account_id = var.target_aws_account_id
  target_vpc_id = module.radius_vpc.vpc_id
  source_vpc_id = module.radius_client_vpc.vpc_id
  source_route_table_ids = module.radius_client_vpc.public_route_table_ids
  destination_route_table_ids = module.radius_vpc.private_route_table_ids
  destination_cidr = local.client_vpc_cidr
}

# module "performance_testing" {
#   source = "./modules/performance_testing"
#   subnets = module.radius_client_vpc.public_subnets
#   vpc_id = module.radius_client_vpc.vpc_id
#   prefix = module.label.id
# }
