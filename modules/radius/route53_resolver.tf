resource "aws_route53_resolver_endpoint" "nac_vpc_outbound" {
  name                = "nac-radius-resolver-${var.short_prefix}"
  direction           = "OUTBOUND"

  security_group_ids  = [
    aws_security_group.radius_server.id
  ]

  ip_address {
    subnet_id = var.vpc.public_subnets[0]
    ip        = var.vpc.private_ip_resolver_eu_west_2a
  }

  ip_address {
    subnet_id = var.vpc.public_subnets[1]
    ip        = var.vpc.private_ip_resolver_eu_west_2b
  }

  ip_address {
    subnet_id = var.vpc.public_subnets[2]
    ip        = var.vpc.private_ip_resolver_eu_west_2c
  }
}

resource "aws_route53_resolver_rule" "nac_dns_rule" {
  name                    = "nac-radius-resolver-rule-${var.short_prefix}"
  rule_type               = "FORWARD"
  domain_name             = var.ocsp_atos_domain
  resolver_endpoint_id    = aws_route53_resolver_endpoint.nac_vpc_outbound.id

  target_ip {
    ip    = "${var.mojo_dns_ip_1}"
    port  = "53"
  }

  target_ip {
    ip    = "${var.mojo_dns_ip_2}"
    port  = "53"
  }
}