module "rds_admin_bastion_label" {
  source       = "./modules/label"
  service_name = "rds-admin-bastion"
  owner_email  = var.owner_email
}

module "rds_admin_bastion" {
  source                      = "./modules/bastion"
  prefix                      = module.rds_admin_bastion_label.id
  vpc_id                      = module.admin_vpc.vpc.vpc_id
  vpc_cidr_block              = module.admin_vpc.vpc.vpc_cidr_block
  private_subnets             = module.admin_vpc.public_subnets
  security_group_ids          = [module.admin.security_group_ids.admin_ecs]
  number_of_bastions          = 1
  assume_role                 = local.s3-mojo_file_transfer_assume_role_arn
  associate_public_ip_address = false
  tags                        = module.rds_admin_bastion_label.tags

  providers = {
    aws = aws.env
  }

  depends_on = [module.admin_vpc]
  // Set in SSM parameter store, true or false to enable or disable this module.
  count = var.enable_rds_admin_bastion == true ? 1 : 0
}
