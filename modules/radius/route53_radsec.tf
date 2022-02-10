resource "aws_route53_record" "radsec" {
  zone_id         = var.hosted_zone_id
  ttl             = 3600
  type            = "CNAME"
  name            = "radsec${var.local_development_domain_affix}"
  records         = [aws_lb.load_balancer.dns_name]
  allow_overwrite = true
}
