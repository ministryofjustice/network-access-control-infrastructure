output "terraform_outputs" {
  value = {
    radius = {
      ecs = module.radius.ecs
    }
  }
}