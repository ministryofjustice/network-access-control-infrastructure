resource "aws_cloudwatch_log_metric_filter" "radius_request_filter" {
  for_each = toset(var.log_filters)

  name           = replace(each.value, ":", "")
  pattern        = format("\"%s\"", each.value)
  log_group_name = aws_cloudwatch_log_group.server_performance_log_group.name

  metric_transformation {
    name          = replace(each.value, ":", "")
    namespace     = var.log_metrics_namespace
    value         = "1"
    default_value = "0"
  }
}

resource "aws_cloudwatch_log_metric_filter" "radius_request_filter" {
  name           = "Sent Access-Accept"
  pattern        = "Sent Access-Accept"
  log_group_name = aws_cloudwatch_log_group.server_performance_log_group.name

  metric_transformation {
    name          = replace(each.value, ":", "")
    namespace     = var.log_metrics_namespace
    value         = "1"
    default_value = "0"
  }
}
