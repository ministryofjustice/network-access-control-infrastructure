resource "aws_lb" "load_balancer" {
  name               = var.prefix
  load_balancer_type = "network"
  internal           = false
  subnet_mapping {
    subnet_id = var.public_subnets[0]
    allocation_id = aws_eip.radius_ip.id
  }

  enable_deletion_protection = false
}

resource "aws_eip" "radius_ip" {
  vpc              = true
  public_ipv4_pool = "amazon"
}

resource "aws_lb_listener" "udp" {
  load_balancer_arn = aws_lb.load_balancer.arn
  port              = "1812"
  protocol          = "UDP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target_group.arn
  }
}

resource "aws_lb_listener" "tcp" {
  load_balancer_arn = aws_lb.load_balancer.arn
  port              = "2083"
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target_group_radsec.arn
  }
}

resource "aws_lb_target_group" "target_group" {
  name                 = var.prefix
  protocol             = "TCP_UDP"
  vpc_id               = var.vpc_id
  port                 = "1812"
  target_type          = "ip"
  deregistration_delay = 300

  health_check {
    port     = 8000
    protocol = "TCP"
  }

  depends_on = [aws_lb.load_balancer]
}

resource "aws_lb_target_group" "target_group_radsec" {
  name                 = "${var.prefix}-radsec"
  protocol             = "TCP"
  vpc_id               = var.vpc_id
  port                 = "2083"
  target_type          = "ip"
  deregistration_delay = 300

  health_check {
    port     = 8000
    protocol = "TCP"
  }

  depends_on = [aws_lb.load_balancer]
}
