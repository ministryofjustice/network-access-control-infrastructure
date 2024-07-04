output "terraform_outputs" {
  value = {
    radius = {
      # ecs = module.radius.ecs
      # ecr = module.radius.ecr
      # lb  = module.radius.load_balancer
      # s3  = module.radius.s3
      vpc = module.radius_vpc.vpc_brief
    }
#     admin = {
#       ecr = module.admin.ecr
#       ecs = module.admin.ecs
#       rds = module.admin.rds
#       vpc = module.admin_vpc.vpc_brief
#     }
#     nat_gateway_public_ip = {
#       value = module.radius_vpc.nat_gateway_eip
#     }
#     nat_gateway_subnet = {
#       value = module.radius_vpc.nat_gateway_subnet_id
#     }
#     nat_gateway_route_table = {
#       value = module.radius_vpc.nat_gateway_route_table_id
#     }
  }
}

# output "rds_bastion" {
#   value = {
#     admin  = module.rds_admin_bastion[*].bastion
#     server = module.rds_servers_bastion[*].bastion
#   }
# }
