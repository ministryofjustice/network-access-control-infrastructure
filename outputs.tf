output "terraform_outputs" {
  value = {
    radius = {
      ecs = module.radius.ecs
      ecr = module.radius.ecr
      s3  = module.radius.s3
    }
    admin = {
      ecr = module.admin.ecr
      ecs = module.admin.ecs
    }
  }
}
