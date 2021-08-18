resource "aws_lb_listener" "letsencrypt_tcp" {
  load_balancer_arn = aws_lb.load_balancer.arn
  port              = "443"
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target_group_letsencrypt.arn
  }
}

resource "aws_lb_listener" "letsencrypt_tcp_http" {
  load_balancer_arn = aws_lb.load_balancer.arn
  port              = "80"
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target_group_letsencrypt_http.arn
  }
}

resource "aws_lb_target_group" "target_group_letsencrypt" {
  name                 = "${var.prefix}-lencrypt"
  protocol             = "TCP"
  vpc_id               = var.vpc_id
  port                 = "443"
  target_type          = "ip"
  deregistration_delay = 300

  health_check {
    port     = 8000
    protocol = "TCP"
  }

  depends_on = [aws_lb.load_balancer]
}

resource "aws_lb_target_group" "target_group_letsencrypt_http" {
  name                 = "${var.prefix}-lencrypt-http"
  protocol             = "TCP"
  vpc_id               = var.vpc_id
  port                 = "80"
  target_type          = "ip"
  deregistration_delay = 300

  health_check {
    port     = 8000
    protocol = "TCP"
  }

  depends_on = [aws_lb.load_balancer]
}
