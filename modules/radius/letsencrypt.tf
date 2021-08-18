resource "aws_acm_certificate" "nac_nlb" {
  domain_name       = "server.${var.hosted_zone_domain}"
  validation_method = "DNS"

  tags = var.tags
}

resource "aws_acm_certificate_validation" "nac_nlb" {
  certificate_arn         = aws_acm_certificate.nac_nlb.arn
  validation_record_fqdns = [for record in aws_route53_record.nac_nlb_validation : record.fqdn]

  depends_on = [
    aws_acm_certificate.nac_nlb
  ]
}

resource "aws_route53_record" "nac_nlb_validation" {
  for_each = {
    for dvo in aws_acm_certificate.nac_nlb.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  name    = each.value.name
  records = [each.value.record]
  ttl     = 3600
  type    = each.value.type
  zone_id = aws_route53_zone.radius.*.zone_id[0]
}
resource "aws_route53_record" "nac_nlb" {
  zone_id = aws_route53_zone.radius.*.zone_id[0]
  ttl     = 3600
  type    = "CNAME"
  name    = "server${var.local_development_domain_affix}"
  records = [aws_lb.load_balancer.dns_name]
}

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
  name                 = "${var.prefix}-le"
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
  name                 = "${var.prefix}-le-http"
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
