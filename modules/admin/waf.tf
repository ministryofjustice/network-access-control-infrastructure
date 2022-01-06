resource "aws_wafv2_web_acl_association" "admin_alb_waf_association" {
  resource_arn = aws_lb.admin_alb.arn
  web_acl_arn  = aws_wafv2_web_acl.admin_alb_acl.arn
}

resource "aws_wafv2_web_acl" "admin_alb_acl" {
  name        = "${var.prefix}-admin-acl"
  description = "Admin WAF ACL"
  scope       = "REGIONAL"

  default_action {
    block {}
  }

  rule {
    name     = "only-gb"
    priority = 1
    action {
      allow {}
    }

    statement {
      geo_match_statement {
        country_codes = ["GB"]
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = var.prefix
      sampled_requests_enabled   = true
    }
  }

  tags = var.tags

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = var.prefix
    sampled_requests_enabled   = true
  }
}
