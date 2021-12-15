resource "aws_appautoscaling_target" "auth_ecs_target" {
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

  depends_on = [aws_appautoscaling_target.auth_ecs_target]
}

resource "aws_appautoscaling_policy" "ecs_policy_down" {
  name               = "ECS Scale Down"
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

  depends_on = [aws_appautoscaling_target.auth_ecs_target]
}

resource "aws_cloudwatch_metric_alarm" "packets_high" {
  alarm_name                = "nacs-packets-per-container-high"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = "2"
  threshold                 = "60"
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
      period      = "60"
      stat        = "Sum"

      dimensions = {
        LoadBalancer = var.load_balancer_arn
      }
    }
  }

  metric_query {
    id = "m2"

    metric {
      metric_name = "CPUUtilization"
      namespace   = "AWS/ECS"
      period      = "60"
      stat        = "SampleCount"

      dimensions = {
        ClusterName = var.cluster_name
        ServiceName = var.service_name
      }
    }
  }
}
