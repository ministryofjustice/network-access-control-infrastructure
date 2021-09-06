resource "aws_db_instance" "admin_db" {
  allocated_storage           = 20
  storage_type                = "gp2"
  engine                      = "mysql"
  engine_version              = "5.7"
  auto_minor_version_upgrade  = true
  allow_major_version_upgrade = false
  apply_immediately           = var.db.apply_updates_immediately
  delete_automated_backups    = var.db.delete_automated_backups
  instance_class              = "db.t2.medium"
  identifier                  = "${var.prefix}-db"
  name                        = replace(var.prefix, "-", "")
  username                    = var.db.username
  password                    = var.db.password
  backup_retention_period     = var.db.backup_retention_period
  multi_az                    = true
  storage_encrypted           = true
  db_subnet_group_name        = aws_db_subnet_group.admin_db_group.name
  vpc_security_group_ids      = [aws_security_group.admin_db.id]
  monitoring_role_arn         = aws_iam_role.rds_monitoring_role.arn
  monitoring_interval         = 60
  skip_final_snapshot         = var.db.skip_final_snapshot
  deletion_protection         = var.db.deletion_protection
  publicly_accessible         = var.is_publicly_accessible

  enabled_cloudwatch_logs_exports = ["audit", "error", "general", "slowquery"]

  parameter_group_name = aws_db_parameter_group.admin_db_parameter_group.name

  tags = var.tags
}

resource "aws_db_subnet_group" "admin_db_group" {
  name       = "${var.prefix}-db-group"
  subnet_ids = var.vpc.private_subnets

  tags = var.tags
}

resource "aws_db_parameter_group" "admin_db_parameter_group" {
  name        = "${var.prefix}-db-parameter-group"
  family      = "mysql5.7"
  description = "Admin DB parameter group"

  parameter {
    name  = "sql_mode"
    value = "STRICT_ALL_TABLES"
  }
  parameter {
    name  = "max_connect_errors"
    value = "10000"
  }
}
