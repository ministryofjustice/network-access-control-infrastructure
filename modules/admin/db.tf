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
  identifier                  = var.prefix
  name                        = replace(var.prefix, "-", "_")
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
  option_group_name           = aws_db_option_group.mariadb_audit.name

  enabled_cloudwatch_logs_exports = ["audit", "error", "general", "slowquery"]

  parameter_group_name = aws_db_parameter_group.admin_db_parameter_group.name

  tags = var.tags
}

resource "aws_db_subnet_group" "admin_db_group" {
  name       = "${var.prefix}-group"
  subnet_ids = var.vpc.private_subnets

  tags = var.tags
}

resource "aws_db_parameter_group" "admin_db_parameter_group" {
  name        = "${var.prefix}-parameter-group"
  family      = "mysql5.7"
  description = "Admin DB parameter group"

  parameter {
    name  = "sql_mode"
    value = "STRICT_ALL_TABLES, NO_AUTO_CREATE_USER"
    apply_method = "pending-reboot"
  }
  parameter {
    name  = "max_connect_errors"
    value = "10000"
    apply_method = "pending-reboot"
  }

  parameter {
    name  = "log_error_verbosity"
    value = "2"
    apply_method = "pending-reboot"
  }

  parameter {
    name  = "validate-password"
    value = "FORCE_PLUS_PERMANENT"
    apply_method = "pending-reboot"
  }

  parameter {
    name  = "validate_password_length"
    value = "14"
    apply_method = "pending-reboot"
  }

  parameter {
    name = "validate_password_mixed_case_count"
    value = "1"
    apply_method = "pending-reboot"
  }

  parameter {
    name = "validate_password_number_count"
    value = "1"
    apply_method = "pending-reboot"
  }

  parameter {
    name  = "validate_password_policy"
    value = "MEDIUM"
    apply_method = "pending-reboot"
  }

  parameter {
    name = "validate_password_special_char_count"
    value = "1"
    apply_method = "pending-reboot"
  }
}

resource "aws_db_option_group" "mariadb_audit" {
  name = "${var.prefix}-db-audit"

  option_group_description = "Mariadb audit configuration"
  engine_name              = "mysql"
  major_engine_version     = "5.7"

  option {
    option_name = "MARIADB_AUDIT_PLUGIN"
  }

  tags = var.tags
}
