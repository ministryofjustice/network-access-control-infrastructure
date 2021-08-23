output "rds" {
  value = {
    name = aws_db_instance.admin_read_replica.name
    host = aws_db_instance.admin_read_replica.address
  }
}
