data "aws_db_snapshot" "latest" {
  db_instance_identifier = aws_db_instance.admin_db.id
  most_recent            = true
}

resource "aws_db_instance" "admin_db_restored" {
  count                       = var.run_restore_from_backup ? 1 : 0
  allocated_storage           = 20
  storage_type                = "gp2"
  engine                      = "mysql"
  engine_version              = "5.7"
  auto_minor_version_upgrade  = true
  allow_major_version_upgrade = false
  apply_immediately           = var.db.apply_updates_immediately
  delete_automated_backups    = true
  instance_class              = "db.t2.medium"
  identifier                  = "${var.prefix}-restored"
  name                        = replace(var.prefix, "-", "_")
  username                    = var.db.username
  password                    = var.db.password
  backup_retention_period     = 1
  multi_az                    = true
  storage_encrypted           = true
  db_subnet_group_name        = aws_db_subnet_group.admin_db_group.name
  vpc_security_group_ids      = [aws_security_group.admin_db.id]
  monitoring_role_arn         = aws_iam_role.rds_monitoring_role.arn
  monitoring_interval         = 60
  skip_final_snapshot         = var.db.skip_final_snapshot
  deletion_protection         = var.db.deletion_protection
  publicly_accessible         = false
  option_group_name           = aws_db_option_group.mariadb_audit.name
  snapshot_identifier         = data.aws_db_snapshot.latest.id

  enabled_cloudwatch_logs_exports = ["audit", "error", "general", "slowquery"]

  parameter_group_name = aws_db_parameter_group.admin_db_parameter_group.name

  tags = var.tags

  lifecycle {
    ignore_changes = [snapshot_identifier]
  }
}
