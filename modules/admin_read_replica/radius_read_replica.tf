resource "aws_db_instance" "admin_read_replica" {
  storage_type                = "gp2"
  engine                      = "mysql"
  engine_version              = "8.0"
  auto_minor_version_upgrade  = true
  allow_major_version_upgrade = false
  apply_immediately           = true
  replicate_source_db         = var.admin_db_arn
  instance_class              = var.db_size
  identifier                  = var.prefix
  multi_az                    = true
  storage_encrypted           = true
  password                    = var.db_password
  db_subnet_group_name        = aws_db_subnet_group.admin_read_relica.name
  vpc_security_group_ids      = [aws_security_group.admin_read_replica.id]
  monitoring_role_arn         = var.rds_monitoring_role
  monitoring_interval         = 60
  skip_final_snapshot         = true
  parameter_group_name        = aws_db_parameter_group.admin_read_replica_parameter_group.name
  deletion_protection         = false

  enabled_cloudwatch_logs_exports = ["audit", "error", "general", "slowquery"]

  lifecycle {
    ignore_changes = [
      "replicate_source_db",
    ]
  }

  tags = var.tags
}

resource "aws_db_subnet_group" "admin_read_relica" {
  name       = "${var.prefix}-group"
  subnet_ids = var.subnet_ids

  tags = var.tags
}

resource "aws_db_parameter_group" "admin_read_replica_parameter_group" {
  name        = "${var.prefix}-parameter-group"
  family      = "mysql8.0"
  description = "Admin Read Replica DB parameter group"

  parameter {
    name  = "sql_mode"
    value = "STRICT_ALL_TABLES"
  }
  parameter {
    name  = "max_connect_errors"
    value = "10000"
  }
}
