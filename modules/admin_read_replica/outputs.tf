output "rds" {
  value = {
    name = aws_db_instance.admin_read_replica_xl.name
    host = aws_db_instance.admin_read_replica_xl.address
    security_group_id = aws_security_group.admin_read_replica.id
  }
}
