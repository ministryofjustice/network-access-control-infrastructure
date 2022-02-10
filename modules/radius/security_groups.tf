resource "aws_security_group" "radius_server" {
  name        = "${var.prefix}-radius-container"
  description = "Allow ingress and egress traffic for radius server"
  vpc_id      = var.vpc.id

  tags = var.tags
}

resource "aws_security_group_rule" "radius_container_healthcheck" {
  description       = "Allow load balancer health checks"
  type              = "ingress"
  from_port         = 8000
  to_port           = 8000
  protocol          = "tcp"
  security_group_id = aws_security_group.radius_server.id
  cidr_blocks       = [var.vpc.cidr]
}

resource "aws_security_group_rule" "radius_container_udp_in" {
  description       = "Allow inbound EAP traffic to the Radius server"
  type              = "ingress"
  from_port         = 1812
  to_port           = 1812
  protocol          = "udp"
  security_group_id = aws_security_group.radius_server.id
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "radius_container_radsec_in" {
  description       = "Allow inbound RADSEC traffic to the Radius server"
  type              = "ingress"
  from_port         = 2083
  to_port           = 2083
  protocol          = "tcp"
  security_group_id = aws_security_group.radius_server.id
  cidr_blocks       = ["0.0.0.0/0"]
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
  description              = "Allow radius server to connect to read replica"
  type                     = "egress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  security_group_id        = aws_security_group.radius_server.id
  source_security_group_id = var.read_replica_security_group_id
}

resource "aws_security_group_rule" "radius_container_ocsp_out" {
  description       = "Allow outbound OCSP requests, this can be to internal or public endpoints"
  type              = "egress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  security_group_id = aws_security_group.radius_server.id
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "dns_1_out" {
  description       = "Allow DNS lookups against the MoJO DNS servers in eu-west-2a"
  type              = "egress"
  from_port         = 53
  to_port           = 53
  protocol          = "udp"
  security_group_id = aws_security_group.radius_server.id
  cidr_blocks       = ["${var.mojo_dns_ip_1}/32"]
}

resource "aws_security_group_rule" "dns_2_out" {
  description       = "Allow DNS lookups against the MoJO DNS servers in eu-west-2b"
  type              = "egress"
  from_port         = 53
  to_port           = 53
  protocol          = "udp"
  security_group_id = aws_security_group.radius_server.id
  cidr_blocks       = ["${var.mojo_dns_ip_2}/32"]
}
