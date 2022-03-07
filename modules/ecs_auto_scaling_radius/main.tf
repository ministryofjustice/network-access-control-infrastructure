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
