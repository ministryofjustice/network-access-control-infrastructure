resource "aws_appautoscaling_target" "admin" {
  service_namespace  = "ecs"
  resource_id        = "service/${var.radius_cluster_name}/${aws_ecs_service.admin.name}"
  max_capacity       = 21
  min_capacity       = 3
  scalable_dimension = "ecs:service:DesiredCount"
}

resource "aws_appautoscaling_policy" "ecs_policy_up" {
  name               = "${var.prefix} ECS Scale Up"
  service_namespace  = "ecs"
  policy_type        = "StepScaling"
  resource_id        = "service/${var.radius_cluster_name}/${aws_ecs_service.admin.name}"
  scalable_dimension = "ecs:service:DesiredCount"

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    metric_aggregation_type = "Average"

    step_adjustment {
      metric_interval_lower_bound = 0
      scaling_adjustment          = 1
    }
  }

  depends_on = [aws_appautoscaling_target.admin]
}

resource "aws_appautoscaling_policy" "ecs_policy_down" {
  name               = "ECS Scale Down"
  service_namespace  = "ecs"
  resource_id        = "service/${var.radius_cluster_name}/${aws_ecs_service.admin.name}"
  policy_type        = "StepScaling"
  scalable_dimension = "ecs:service:DesiredCount"

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    metric_aggregation_type = "Average"

    step_adjustment {
      metric_interval_upper_bound = 0
      scaling_adjustment          = -1
    }
  }

  depends_on = [aws_appautoscaling_target.admin]
}

resource "aws_cloudwatch_metric_alarm" "ecs_cpu_alarm_high" {
  alarm_name          = "${var.prefix}-ecs-cpu-alarm-high"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "60"
  statistic           = "Average"
  threshold           = "70"

  dimensions = {
    ClusterName = var.radius_cluster_name
    ServiceName = aws_ecs_service.admin.name
  }

  alarm_description = "This alarm tells ECS to scale out based on high CPU usage"

  alarm_actions = [
    aws_appautoscaling_policy.ecs_policy_up.arn
  ]

  treat_missing_data = "breaching"

  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "ecs_cpu_alarm_low" {
  alarm_name          = "${var.prefix}-ecs-cpu-alarm-low"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "60"
  statistic           = "Average"
  threshold           = "15"

  dimensions = {
    ClusterName = var.radius_cluster_name
    ServiceName = aws_ecs_service.admin.name
  }

  alarm_description = "This alarm tells ECS to scale in based on low CPU usage"

  alarm_actions = [
    aws_appautoscaling_policy.ecs_policy_down.arn
  ]

  treat_missing_data = "breaching"

  tags = var.tags
}
