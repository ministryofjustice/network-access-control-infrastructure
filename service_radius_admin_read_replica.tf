## This admin RDS resource is located inside the radius VPC
module "admin_read_replica" {
  source                          = "./modules/admin_read_replica"
  replication_source              = module.admin.rds.admin_db_arn
  subnet_ids                      = module.radius_vpc.private_subnets
  rds_monitoring_role             = module.admin.rds.rds_monitoring_role
  vpc_id                          = module.radius_vpc.vpc_id
  db_password                     = jsondecode(data.aws_secretsmanager_secret_version.moj_network_access_control_env_admin_db.secret_string)["password"]
  db_size                         = "db.t3.large"
  radius_server_security_group_id = module.radius.ec2.radius_server_security_group_id
  prefix                          = "${module.label.id}-admin-read-replica"
  tags                            = module.label.tags

  providers = {
    aws = aws.env
  }
}
