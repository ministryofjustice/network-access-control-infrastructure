output "flow_log_group_id" {
  value = aws_cloudwatch_log_group.vpc_flow_logs_log_group.arn
}
