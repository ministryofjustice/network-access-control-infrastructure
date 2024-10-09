module "admin_vpc" {
  source                        = "./modules/admin_vpc"
  prefix                        = "${module.label.id}-admin"
  region                        = data.aws_region.current_region.id
  cidr_block                    = "10.0.0.0/16"
  tags                          = module.label.tags
#   ssm_session_manager_endpoints = var.enable_rds_admin_bastion

  providers = {
    aws = aws.env
  }
}

module "admin_vpc_flow_logs" {
  source = "./modules/vpc_flow_logs"
  prefix = "${module.label.id}-admin-vpc-flow-logs"
  region = data.aws_region.current_region.id
  tags   = module.label.tags
  vpc_id = module.admin_vpc.vpc_id

  providers = {
    aws = aws.env
  }
}
