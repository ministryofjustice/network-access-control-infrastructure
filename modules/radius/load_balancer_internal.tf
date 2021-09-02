resource "aws_lb" "internal_load_balancer" {
  name                             = "nac-int-${var.prefix}"
  load_balancer_type               = "network"
  internal                         = true
  enable_cross_zone_load_balancing = true
  subnet_mapping {
    subnet_id = var.vpc.private_subnets[0]
    private_ipv4_address = var.vpc.private_ip_eu_west_2a
  }

  subnet_mapping {
    subnet_id = var.vpc.private_subnets[1]
    private_ipv4_address = var.vpc.private_ip_eu_west_2b
  }

  subnet_mapping {
    subnet_id = var.vpc.private_subnets[2]
    private_ipv4_address = var.vpc.private_ip_eu_west_2c
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
  vpc_id               = var.vpc.id
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
  name                 = "nac-radsec-int-${var.short_prefix}"
  protocol             = "TCP"
  vpc_id               = var.vpc.id
  port                 = "2083"
  target_type          = "ip"
  deregistration_delay = 300

  health_check {
    port     = 8000
    protocol = "TCP"
  }

  depends_on = [aws_lb.internal_load_balancer]
}
