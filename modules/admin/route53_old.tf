resource "aws_acm_certificate" "admin_alb" {
  domain_name       = "admin.${var.hosted_zone_domain_old}"
  validation_method = "DNS"

  tags = var.tags
}

resource "aws_acm_certificate_validation" "admin_alb" {
  certificate_arn         = aws_acm_certificate.admin_alb.arn
  validation_record_fqdns = [for record in aws_route53_record.admin_alb : record.fqdn]
}

resource "aws_route53_record" "admin_alb" {
  for_each = {
    for dvo in aws_acm_certificate.admin_alb.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  name    = each.value.name
  records = [each.value.record]
  ttl     = 3600
  type    = each.value.type
  zone_id = var.hosted_zone_id_old
}

resource "aws_route53_record" "admin_app" {
  zone_id = var.hosted_zone_id_old
  ttl     = 3600
  type    = "CNAME"
  set_identifier = "geolocation"
  geolocation_routing_policy {
    country = "GB"
  }

  name    = "admin${var.local_development_domain_affix}"
  records = [aws_lb.admin_alb.dns_name]
  allow_overwrite = true
}

resource "aws_route53_record" "admin_db" {
  zone_id = var.hosted_zone_id_old
  ttl     = 3600
  type    = "CNAME"

  set_identifier = "geolocation"
  geolocation_routing_policy {
    country = "GB"
  }

  name    = "admin-db${var.local_development_domain_affix}"
  records = [aws_db_instance.admin_db.address]
  allow_overwrite = true
}
