module "rds_servers_bastion_label" {
  source       = "./modules/label"
  service_name = "rds-servers-bastion"
  owner_email  = var.owner_email
}

module "rds_servers_bastion" {
  source                      = "./modules/bastion"
  prefix                      = module.rds_servers_bastion_label.id
  vpc_id                      = module.radius_vpc.vpc.vpc_id
  vpc_cidr_block              = module.radius_vpc.vpc.vpc_cidr_block
  private_subnets             = module.radius_vpc.private_subnets
  security_group_ids          = [module.radius.security_group_ids.radius_server]
  ami_name                    = "diso-devops/bastion/rds-admin/ubuntu-jammy-22.04-amd64-server-1.0.1"
  number_of_bastions          = 1
  assume_role                 = local.s3-mojo_file_transfer_assume_role_arn
  associate_public_ip_address = false
  tags                        = module.rds_servers_bastion_label.tags

  providers = {
    aws = aws.env
  }

  depends_on = [module.radius_vpc]
  // Set in SSM parameter store, true or false to enable or disable this module.
  count = var.enable_rds_servers_bastion == true ? 1 : 0
}
