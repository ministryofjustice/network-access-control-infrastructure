resource "aws_acm_certificate" "nac_nlb" {
  domain_name       = "server.${var.hosted_zone_domain}"
  validation_method = "DNS"

  tags = var.tags
}

resource "aws_acm_certificate_validation" "nac_nlb" {
  certificate_arn         = aws_acm_certificate.nac_nlb.arn
  validation_record_fqdns = [for record in aws_route53_record.nac_nlb : record.fqdn]

  depends_on = [
    aws_acm_certificate.nac_nlb
  ]
}

resource "aws_route53_record" "nac_nlb" {
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
