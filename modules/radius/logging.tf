resource "aws_cloudwatch_log_group" "server_log_group" {
  name = "${var.prefix}-server-log-group"

  retention_in_days = 7

  tags = var.tags
}

resource "aws_cloudwatch_log_group" "server_performance_log_group" {
  name = "${var.prefix}-server-performance-log-group"

  retention_in_days = 1

  tags = var.tags
}

resource "aws_cloudwatch_log_group" "server_nginx_log_group" {
  name = "${var.prefix}-server-nginx-log-group"

  retention_in_days = 7

  tags = var.tags
}
