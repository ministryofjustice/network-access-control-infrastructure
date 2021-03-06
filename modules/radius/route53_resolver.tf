resource "aws_route53_resolver_endpoint" "nac_vpc_outbound" {
  count = var.enable_ocsp_dns_resolver ? 1 : 0

  name      = "nac-radius-resolver-${var.short_prefix}"
  direction = "OUTBOUND"

  security_group_ids = [
    aws_security_group.radius_server.id
  ]

  ip_address {
    subnet_id = var.vpc.private_subnets[0]
  }

  ip_address {
    subnet_id = var.vpc.public_subnets[0]
  }

  tags = var.tags
}

resource "aws_route53_resolver_rule" "nac_dns_rule" {
  count = var.enable_ocsp_dns_resolver ? 1 : 0

  name                 = "nac-radius-resolver-rule-${var.short_prefix}"
  rule_type            = "FORWARD"
  domain_name          = var.ocsp_atos_domain
  resolver_endpoint_id = aws_route53_resolver_endpoint.nac_vpc_outbound.*.id[0]

  target_ip {
    ip   = var.mojo_dns_ip_1
    port = "53"
  }

  target_ip {
    ip   = var.mojo_dns_ip_2
    port = "53"
  }

  tags = var.tags
}

resource "aws_route53_resolver_rule_association" "nac_dns_rule_association" {
  count = var.enable_ocsp_dns_resolver ? 1 : 0

  resolver_rule_id = aws_route53_resolver_rule.nac_dns_rule.*.id[0]
  vpc_id           = var.vpc.id
}

resource "aws_route53_resolver_query_log_config" "nac_resolver_query_log" {
  name            = "nac-resolver-query-log-${var.short_prefix}"
  destination_arn = var.vpc_flow_logs_group_id

  tags = var.tags
}

resource "aws_route53_resolver_query_log_config_association" "nac_resolver_query_log_association" {
  resolver_query_log_config_id = aws_route53_resolver_query_log_config.nac_resolver_query_log.id
  resource_id                  = var.vpc.id
}
