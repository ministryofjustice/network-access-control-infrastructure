output "terraform_outputs" {
  value = {
    radius = {
      ecs = module.radius.ecs
      ecr = module.radius.ecr
    }
    admin = {
      ecr = module.admin.ecr
    }
  }
}
