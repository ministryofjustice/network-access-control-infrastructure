module "performance_testing" {
  source                   = "./modules/performance_testing"
  count                    = local.is_development ? 1 : 0
  prefix                   = "${module.label.id}-perf"
  vpc_id                   = module.radius_vpc.vpc_id
  subnets                  = module.radius_vpc.public_subnets
  load_balancer_ip_address = module.radius.load_balancer.nac_eu_west_2a_ip_address

  providers = {
    aws = aws.env
  }
}
