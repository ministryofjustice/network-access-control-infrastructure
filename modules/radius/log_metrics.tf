resource "aws_cloudwatch_log_metric_filter" "radius_request_filter" {
  for_each = toset(var.log_filters)

  name           = replace(each.value, ":", "")
  pattern        = format("\"%s\"", each.value)
  log_group_name = aws_cloudwatch_log_group.server_log_group.name

  metric_transformation {
    name          = replace(each.value, ":", "")
    namespace     = "mojo-nac-requests"
    value         = "1"
    default_value = "0"
  }
}
