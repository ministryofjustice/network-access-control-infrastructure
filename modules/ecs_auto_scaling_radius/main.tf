resource "aws_appautoscaling_target" "radius" {
  service_namespace  = "ecs"
  resource_id        = "service/${var.cluster_name}/${var.service_name}"
  max_capacity       = 21
  min_capacity       = 3
  scalable_dimension = "ecs:service:DesiredCount"
}

resource "aws_appautoscaling_policy" "ecs_policy_up" {
  name               = "${var.prefix} ECS Scale Up"
  service_namespace  = "ecs"
  policy_type        = "StepScaling"
  resource_id        = "service/${var.cluster_name}/${var.service_name}"
  scalable_dimension = "ecs:service:DesiredCount"

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    metric_aggregation_type = "Average"

    step_adjustment {
      metric_interval_lower_bound = 0
      scaling_adjustment          = 1
    }
  }

  depends_on = [aws_appautoscaling_target.radius]
}
// Scaling out using memory_average utilisation
resource "aws_appautoscaling_policy" "ecs_policy_up_memory_average" {
  name               = "${var.prefix} ECS Scale Up Memory Average"
  service_namespace  = "ecs"
  policy_type        = "StepScaling"
  resource_id        = "service/${var.cluster_name}/${var.service_name}"
  scalable_dimension = "ecs:service:DesiredCount"

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    metric_aggregation_type = "Average"

    step_adjustment {
      metric_interval_lower_bound = 0
      scaling_adjustment          = 1
    }
  }

  depends_on = [aws_appautoscaling_target.radius]
}

resource "aws_appautoscaling_policy" "ecs_policy_up_memory_max" {
  name               = "${var.prefix} ECS Scale Up Memory Maximum"
  service_namespace  = "ecs"
  policy_type        = "StepScaling"
  resource_id        = "service/${var.cluster_name}/${var.service_name}"
  scalable_dimension = "ecs:service:DesiredCount"

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    metric_aggregation_type = "Maximum"
    cooldown                = 300

    step_adjustment {
      metric_interval_lower_bound = 0
      scaling_adjustment          = 1
    }
  }

  depends_on = [aws_appautoscaling_target.radius]
}

resource "aws_appautoscaling_policy" "ecs_policy_down" {
  name               = "${var.prefix} ECS Scale Down"
  service_namespace  = "ecs"
  resource_id        = "service/${var.cluster_name}/${var.service_name}"
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

  depends_on = [aws_appautoscaling_target.radius]
}

resource "aws_cloudwatch_metric_alarm" "packets_high" {
  alarm_name                = "${var.prefix}-packets-per-container-high"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = "2"
  threshold                 = "10000"
  alarm_description         = "Packets processed per container"
  insufficient_data_actions = []

  metric_query {
    id          = "e1"
    expression  = "m1/m2"
    label       = "Packet count per container"
    return_data = "true"
  }

  metric_query {
    id = "m1"

    metric {
      metric_name = "ProcessedPackets"
      namespace   = "AWS/NetworkELB"
      period      = "300"
      stat        = "Sum"

      dimensions = {
        LoadBalancer = var.load_balancer_arn_suffix
      }
    }
  }

  metric_query {
    id = "m2"

    metric {
      metric_name = "CPUUtilization"
      namespace   = "AWS/ECS"
      period      = "300"
      stat        = "SampleCount"

      dimensions = {
        ClusterName = var.cluster_name
        ServiceName = var.service_name
      }
    }
  }

  alarm_actions = [
    aws_appautoscaling_policy.ecs_policy_up.arn
  ]

  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "packets_low" {
  alarm_name                = "${var.prefix}-packets-per-container-low"
  comparison_operator       = "LessThanThreshold"
  evaluation_periods        = "2"
  threshold                 = "8000"
  alarm_description         = "Packets processed per container"
  insufficient_data_actions = []

  metric_query {
    id          = "e1"
    expression  = "m1/m2"
    label       = "Packet count per container"
    return_data = "true"
  }

  metric_query {
    id = "m1"

    metric {
      metric_name = "ProcessedPackets"
      namespace   = "AWS/NetworkELB"
      period      = "300"
      stat        = "Sum"

      dimensions = {
        LoadBalancer = var.load_balancer_arn_suffix
      }
    }
  }

  metric_query {
    id = "m2"

    metric {
      metric_name = "CPUUtilization"
      namespace   = "AWS/ECS"
      period      = "300"
      stat        = "SampleCount"

      dimensions = {
        ClusterName = var.cluster_name
        ServiceName = var.service_name
      }
    }
  }

  alarm_actions = [
    aws_appautoscaling_policy.ecs_policy_down.arn
  ]

  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "ecs_memory_average_alarm" {
  alarm_name          = "${var.prefix}-ecs-memory-average-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/ECS"
  period              = "60"
  statistic           = "Average"
  threshold           = "70"

  dimensions = {
    ClusterName = var.cluster_name
    ServiceName = var.service_name
  }

  alarm_description = "This alarm tells ECS to scale up based on memory utilisation with AVERAGE statistics"

  alarm_actions = [
    aws_appautoscaling_policy.ecs_policy_up_memory_average.arn
  ]

  treat_missing_data = "breaching"
  tags               = var.tags
}

resource "aws_cloudwatch_metric_alarm" "ecs_memory_maximum_alarm_high" {
  alarm_name          = "${var.prefix}-ecs-memory-maximum-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/ECS"
  period              = "60"
  statistic           = "Maximum"
  threshold           = "80"

  dimensions = {
    ClusterName = var.cluster_name
    ServiceName = var.service_name
  }

  alarm_description = "This alarm tells ECS to scale up based on memory utilisation with MAXIMUM statistics"

  alarm_actions = [
    aws_appautoscaling_policy.ecs_policy_up_memory_max.arn
  ]

  treat_missing_data = "breaching"
  tags               = var.tags
}
