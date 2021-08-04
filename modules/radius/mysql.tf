locals {
  is_production = terraform.workspace == "production" ? true : false
}
resource "aws_db_instance" "radius_server_db" {
  allocated_storage           = 20
  storage_type                = "gp2"
  engine                      = "mysql"
  engine_version              = "5.7"
  auto_minor_version_upgrade  = true
  allow_major_version_upgrade = false
  apply_immediately           = true
  instance_class              = local.is_production ? "db.t3.xlarge" : "db.t2.medium"
  identifier                  = "${var.prefix}-db"
  name                        = replace(var.prefix, "-", "")
  username                    = var.radius_db_username
  password                    = var.radius_db_password
  backup_retention_period     = "0"
  multi_az                    = local.is_production ? true : false
  storage_encrypted           = true
  db_subnet_group_name        = aws_db_subnet_group.db.name
  vpc_security_group_ids      = [aws_security_group.radius_db_in.id]
  publicly_accessible         = local.is_production ? false : true
  monitoring_role_arn         = aws_iam_role.rds_monitoring_role.arn
  monitoring_interval         = 30
  skip_final_snapshot         = true
  deletion_protection         = local.is_production ? true : false

  enabled_cloudwatch_logs_exports = ["audit", "error", "general", "slowquery"]

  parameter_group_name = aws_db_parameter_group.radius_db_parameter_group.name
}

resource "aws_db_subnet_group" "db" {
  name       = "${var.prefix}-main"
  subnet_ids = var.public_subnets
}

resource "aws_db_parameter_group" "radius_db_parameter_group" {
  name        = "${var.prefix}-db-parameter-group"
  family      = "mysql5.7"
  description = "RADIUS DB parameter group"

  parameter {
    name  = "sql_mode"
    value = "STRICT_ALL_TABLES"
  }
}
