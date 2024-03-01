output "terraform_outputs" {
  value = {
    radius = {
      ecs = module.radius.ecs
      ecr = module.radius.ecr
      lb  = module.radius.load_balancer
      s3  = module.radius.s3
      vpc = module.radius_vpc.vpc_brief
    }
    admin = {
      ecr = module.admin.ecr
      ecs = module.admin.ecs
      rds = module.admin.rds
      vpc = module.admin_vpc.vpc_brief
    }
  }
}
