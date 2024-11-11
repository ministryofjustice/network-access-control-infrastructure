module "rds_admin_bastion_label" {
  source       = "./modules/label"
  service_name = "rds-admin-bastion"
  owner_email  = var.owner_email
}

module "rds_admin_bastion" {
  source                      = "github.com/ministryofjustice/diso-devops-module-ssm-bastion"
  prefix                      = module.rds_admin_bastion_label.id
  ami_owners                  = ["${local.shared_services_account_id}"]
  associate_public_ip_address = false
  assume_role                 = local.s3-mojo_file_transfer_assume_role_arn
  number_of_bastions          = 1
  security_group_ids          = [module.admin.security_group_ids.admin_ecs]
  subnets                     = module.admin_vpc.public_subnets
  vpc_cidr_block              = module.admin_vpc.vpc.vpc_cidr_block
  vpc_id                      = module.admin_vpc.vpc.vpc_id
  tags                        = module.rds_admin_bastion_label.tags

  providers = {
    aws = aws.env
  }

  depends_on = [module.admin_vpc]
  // Set in SSM parameter store, true or false to enable or disable this module.
  count = local.enable_rds_admin_bastion == true ? 1 : 0
}
