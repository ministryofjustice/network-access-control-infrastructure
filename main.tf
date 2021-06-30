terraform {
  backend "s3" {
    bucket         = "pttp-ci-infrastructure-nac-client-core-tf-state"
    dynamodb_table = "pttp-ci-infrastructure-nac-client-core-tf-lock-table"
    region         = "eu-west-2"
  }

  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version               = "~> 3.0"
      configuration_aliases = [aws.env]
    }
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
  version = "0.24.1"

  delimiter = "-"
  namespace = "mojo"
  stage     = terraform.workspace
  name      = var.service_name

  tags = {
    "business-unit"    = "MoJO"
    "application"      = "nac",
    "is-production"    = "true"
    "owner"            = "nac@digital.justice.gov.uk"
    "environment-name" = "global"
    "source-code"      = "https://github.com/ministryofjustice/network-access-control-infrastructure"
  }
}


locals {
  private_ip_eu_west_2a = "10.180.100.10"
  private_ip_eu_west_2b = "10.180.101.10"
  private_ip_eu_west_2c = "10.180.102.10"
  vpc_cidr              = "10.180.100.0/22"
  client_vpc_cidr       = "192.168.0.0/16"
}

module "radius" {
  source                = "./modules/radius"
  prefix                = module.label.id
  short_prefix          = "${module.label.stage}-nac"
  vpc_id                = module.radius_vpc.vpc_id
  private_ip_eu_west_2a = local.private_ip_eu_west_2a
  private_ip_eu_west_2b = local.private_ip_eu_west_2b
  private_ip_eu_west_2c = local.private_ip_eu_west_2c
  public_subnets        = module.radius_vpc.public_subnets
  private_subnets       = module.radius_vpc.private_subnets
  vpc_cidr              = local.vpc_cidr
  radius_db_username    = var.radius_db_username
  radius_db_password    = var.radius_db_password
  log_filters = [
    "Accept",
    "Reject",
    "did not finish"
  ]
  providers = {
    aws = aws.env
  }
}

module "radius_vpc" {
  source     = "./modules/vpc"
  prefix     = module.label.id
  cidr_block = local.vpc_cidr

  providers = {
    aws = aws.env
  }
}

module "radius_client_vpc" {
  source     = "./modules/vpc"
  prefix     = module.label.id
  cidr_block = local.client_vpc_cidr
  providers = {
    aws = aws.env
  }
}

module "radius_vpc_flow_logs" {
  source = "./modules/vpc_flow_logs"
  prefix = module.label.id
  region = "eu-west-2"
  vpc_id = module.radius_vpc.vpc_id
  tags   = module.label.tags

  providers = {
    aws = aws.env
  }
}

module "admin" {
  source                               = "./modules/admin"
  prefix                               = "${module.label.id}-admin"
  short_prefix                         = module.label.stage # avoid 32 char limit on certain resources
  tags                                 = module.label.tags
  vpc_id                               = module.admin_vpc.vpc_id
  admin_db_password                    = var.admin_db_password
  admin_db_username                    = var.admin_db_username
  subnet_ids                           = module.admin_vpc.public_subnets
  sentry_dsn                           = var.admin_sentry_dsn
  secret_key_base                      = "tbc"
  radius_certificate_bucket_arn        = module.radius.s3.radius_certificate_bucket_arn
  radius_certificate_bucket_name       = module.radius.s3.radius_certificate_bucket_name
  region                               = data.aws_region.current_region.id
  vpn_hosted_zone_id                   = var.vpn_hosted_zone_id
  vpn_hosted_zone_domain               = var.vpn_hosted_zone_domain
  admin_db_backup_retention_period     = var.admin_db_backup_retention_period
  # cognito_user_pool_id                 = module.authentication.cognito_user_pool_id
  # cognito_user_pool_domain             = module.authentication.cognito_user_pool_domain
  # cognito_user_pool_client_id          = module.authentication.cognito_user_pool_client_id
  # cognito_user_pool_client_secret      = module.authentication.cognito_user_pool_client_secret
  radius_cluster_name                  = module.radius.ecs.radius_cluster_name
  radius_service_name                  = module.radius.ecs.radius_service_name
  radius_service_arn                   = module.radius.ecs.radius_service_arn
  is_publicly_accessible               = local.publicly_accessible
  admin_local_development_domain_affix = var.admin_local_development_domain_affix

  depends_on = [
    module.admin_vpc
  ]

  providers = {
    aws = aws.env
  }
}

locals {
  publicly_accessible = terraform.workspace == "production" ? false : true
}

# module "authentication" {
#   source                        = "./modules/cognito"
#   azure_federation_metadata_url = var.azure_federation_metadata_url
#   prefix                        = module.label.id
#   enable_authentication         = var.enable_authentication
#   admin_url                     = module.admin.admin_url
#   region                        = data.aws_region.current_region.id
#   vpn_hosted_zone_domain        = var.vpn_hosted_zone_domain

#   providers = {
#     aws = aws.env
#   }
# }

data "aws_region" "current_region" {}
data "aws_caller_identity" "shared_services_account" {}

module "admin_vpc" {
  source     = "./modules/admin_vpc"
  prefix     = "${module.label.id}-admin"
  region     = data.aws_region.current_region.id
  cidr_block = "10.0.0.0/16"

  providers = {
    aws = aws.env
  }
}

module "admin_vpc_flow_logs" {
  source = "./modules/vpc_flow_logs"
  prefix = "nac-admin-${terraform.workspace}"
  region = data.aws_region.current_region.id
  tags   = module.label.tags
  vpc_id = module.admin_vpc.vpc_id

  providers = {
    aws = aws.env
  }
}

# module "vpc_peering_internal_authentication" {
#  source = "./modules/vpc_peering_internal_authentication"
#  target_aws_account_id = var.target_aws_account_id
#  target_vpc_id = module.radius_vpc.vpc_id
#  source_vpc_id = module.radius_client_vpc.vpc_id
#  source_route_table_ids = module.radius_client_vpc.public_route_table_ids
#  destination_route_table_ids = module.radius_vpc.private_route_table_ids
#  destination_cidr = local.client_vpc_cidr
# }

# module "performance_testing" {
#   source = "./modules/performance_testing"
#   subnets = module.radius_client_vpc.public_subnets
#   vpc_id = module.radius_client_vpc.vpc_id
#   prefix = module.label.id
# }
