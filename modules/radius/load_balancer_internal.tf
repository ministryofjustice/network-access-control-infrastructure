resource "aws_lb" "internal_load_balancer" {
  name               = "${var.prefix}-private"
  load_balancer_type = "network"
  internal           = true
  subnet_mapping {
    subnet_id = var.private_subnets[0]
    private_ipv4_address = var.private_ip_eu_west_2a
  }

  subnet_mapping {
    subnet_id = var.private_subnets[1]
    private_ipv4_address = var.private_ip_eu_west_2b
  }

  enable_deletion_protection = false
}

resource "aws_lb_listener" "internal_udp" {
  load_balancer_arn = aws_lb.internal_load_balancer.arn
  port              = "1812"
  protocol          = "UDP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.internal_target_group.arn
  }
}

resource "aws_lb_listener" "internal_udp-ttls" {
  load_balancer_arn = aws_lb.internal_load_balancer.arn
  port              = "1814"
  protocol          = "UDP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.internal_target_group_ttls.arn
  }
}

resource "aws_lb_listener" "internal_tcp" {
  load_balancer_arn = aws_lb.internal_load_balancer.arn
  port              = "2083"
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.internal_target_group_radsec.arn
  }
}

resource "aws_lb_target_group" "internal_target_group" {
  name                 = "${var.prefix}-private"
  protocol             = "TCP_UDP"
  vpc_id               = var.vpc_id
  port                 = "1812"
  target_type          = "ip"
  deregistration_delay = 300

  health_check {
    port     = 8000
    protocol = "TCP"
  }

  depends_on = [aws_lb.internal_load_balancer]
}

resource "aws_lb_target_group" "internal_target_group_radsec" {
  name                 = "${var.prefix}-radsec-int"
  protocol             = "TCP"
  vpc_id               = var.vpc_id
  port                 = "2083"
  target_type          = "ip"
  deregistration_delay = 300

  health_check {
    port     = 8000
    protocol = "TCP"
  }

  depends_on = [aws_lb.internal_load_balancer]
}
