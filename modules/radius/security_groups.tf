resource "aws_security_group" "radius_server" {
  name        = "${var.prefix}-radius-container"
  description = "Allow the ECS agent to talk to the ECS endpoints"
  vpc_id      = var.vpc_id
}

resource "aws_security_group_rule" "radius_container_healthcheck" {
  description       = "Allow health checks from the Load Balancer"
  type              = "ingress"
  from_port         = 8000
  to_port           = 8000
  protocol          = "tcp"
  security_group_id = aws_security_group.radius_server.id
  cidr_blocks       = [var.vpc_cidr]
}

resource "aws_security_group_rule" "radius_container_udp_in" {
  description       = "Allow inbound traffic to the Radius server"
  type              = "ingress"
  from_port         = 1812
  to_port           = 1812
  protocol          = "udp"
  security_group_id = aws_security_group.radius_server.id
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "radius_container_radsec_in" {
  description       = "Allow RADSEC inbound traffic to the Radius server"
  type              = "ingress"
  from_port         = 2083
  to_port           = 2083
  protocol          = "tcp"
  security_group_id = aws_security_group.radius_server.id
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "radius_container_udp_out" {
  description       = "Allow outbound traffic to RADIUS client from the Radius server"
  type              = "egress"
  from_port         = 0
  to_port           = 65000
  protocol          = "udp"
  security_group_id = aws_security_group.radius_server.id
  cidr_blocks       = [var.vpc_cidr]
}

resource "aws_security_group_rule" "radius_container_web_out" {
  description       = "Allow SSL outbound connections from the container"
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  security_group_id = aws_security_group.radius_server.id
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "radius_container_db_out" {
  type                     = "egress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  security_group_id        = aws_security_group.radius_server.id
  source_security_group_id = var.read_replica_security_group_id
}

resource "aws_security_group_rule" "ocsp_out" {
  type              = "egress"
  from_port         = var.ocsp_endpoint_port
  to_port           = var.ocsp_endpoint_port
  protocol          = "tcp"
  security_group_id        = aws_security_group.radius_server.id
  cidr_blocks       = ["${var.ocsp_endpoint_ip}/32"]
}
