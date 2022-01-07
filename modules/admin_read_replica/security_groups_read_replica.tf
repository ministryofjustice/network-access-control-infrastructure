resource "aws_security_group" "admin_read_replica" {
  name        = var.prefix
  description = "Allow traffic to and from the admin read replica"
  vpc_id      = var.vpc_id

  tags = var.tags
}

resource "aws_security_group_rule" "radius_db_in" {
  type                     = "ingress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  security_group_id        = aws_security_group.admin_read_replica.id
  source_security_group_id = var.radius_server_security_group_id
}
