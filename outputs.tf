output "terraform_outputs" {
  value = {
    radius = {
      ecs = module.radius.ecs
    }
    admin = {
      ecr = module.admin.ecr
    }
  }
}
