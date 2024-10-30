module "authentication" {
  source                        = "./modules/cognito"
  azure_federation_metadata_url = local.azure_federation_metadata_url
  prefix                        = module.label.id
  enable_authentication         = var.enable_authentication
  admin_url                     = module.admin.admin_url
  region                        = data.aws_region.current_region.id
  hosted_zone_domain            = local.hosted_zone_domain

  providers = {
    aws = aws.env
  }
}
