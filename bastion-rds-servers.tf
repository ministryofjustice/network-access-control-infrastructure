module "rds_servers_bastion_label" {
  source       = "./modules/label"
  service_name = "rds-servers-bastion"
  owner_email  = var.owner_email
}

module "rds_servers_bastion" {
  source                      = "github.com/ministryofjustice/diso-devops-module-ssm-bastion.git?depth=1&ref=aws_provider_v4_for_nac"
  prefix                      = module.rds_servers_bastion_label.id
  ami_owners                  = ["${var.shared_services_account_id}"]
  associate_public_ip_address = false
  assume_role                 = local.s3-mojo_file_transfer_assume_role_arn
  number_of_bastions          = 1
  security_group_ids          = [module.radius.security_group_ids.radius_server]
  subnets                     = module.radius_vpc.private_subnets
  vpc_cidr_block              = module.radius_vpc.vpc.vpc_cidr_block
  vpc_id                      = module.radius_vpc.vpc.vpc_id
  tags                        = module.rds_servers_bastion_label.tags

  providers = {
    aws = aws.env
  }

  depends_on = [module.radius_vpc]
  // Set in SSM parameter store, true or false to enable or disable this module.
  count = var.enable_rds_servers_bastion == true ? 1 : 0
}
