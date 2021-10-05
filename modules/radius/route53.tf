locals {
  zone_prefixes = {
    "development" = "dev.",
    "pre-production" = "prep."
  }
}
resource "aws_route53_zone" "radius_service" {
  count = var.enable_hosted_zone ? 1 : 0

  name = "${lookup(local.zone_prefixes, var.env, "")}network-access-control.service.justice.gov.uk"

  tags = var.tags
}
