resource "aws_cloudwatch_log_metric_filter" "radius_request_filter" {
  for_each = toset([for i in var.log_filters : replace(i, ":", "") if !(length(regexall("\\?", i)) > 0)])

  name           = replace(each.value, ":", "")
  pattern        = format("\"%s\"", each.value)
  log_group_name = aws_cloudwatch_log_group.server_log_group.name

  metric_transformation {
    name          = replace(each.value, ":", "")
    namespace     = var.log_metrics_namespace
    value         = "1"
    default_value = "0"
  }
}

resource "aws_cloudwatch_log_metric_filter" "radius_request_filter_with_queries" {
  for_each = toset([for i in var.log_filters : replace(i, ":", "") if length(regexall("\\?", i)) > 0])

  name           = regexall("error", each.value) > 0 ? "All other errors" : regex("[[:alpha:]]+", each.value)
  pattern        = replace(each.value, "'", "\"")
  log_group_name = aws_cloudwatch_log_group.server_log_group.name

  metric_transformation {
    name          = regexall("error", each.value) > 0 ? "All other errors" : regex("[[:alpha:]]+", each.value)
    namespace     = var.log_metrics_namespace
    value         = "1"
    default_value = "0"
    unit          = "Count"
  }
}
