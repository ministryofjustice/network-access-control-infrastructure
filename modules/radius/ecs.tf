resource "aws_ecs_cluster" "server_cluster" {
  name = "${var.prefix}-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = var.tags
}

resource "aws_ecs_service" "service" {
  name            = "${var.prefix}-service"
  cluster         = aws_ecs_cluster.server_cluster.id
  task_definition = aws_ecs_task_definition.server_task.arn
  desired_count   = 3
  launch_type     = "FARGATE"

  load_balancer {
    target_group_arn = aws_lb_target_group.target_group.arn
    container_name   = "radius-server"
    container_port   = 1812
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.target_group_radsec.arn
    container_name   = "radius-server"
    container_port   = 2083
  }

  network_configuration {
      subnets = [
        var.vpc.public_subnets[0],
        var.vpc.public_subnets[1],
        var.vpc.public_subnets[2]
      ]

    security_groups = [
      aws_security_group.radius_server.id
    ]

    assign_public_ip = true
  }

  lifecycle {
    ignore_changes = ["desired_count"]
  }
}

resource "aws_ecs_service" "internal_service" {
  name            = "${var.prefix}-internal-service"
  cluster         = aws_ecs_cluster.server_cluster.id
  task_definition = aws_ecs_task_definition.server_task.arn
  desired_count   = 3
  launch_type     = "FARGATE"

  load_balancer {
    target_group_arn = aws_lb_target_group.internal_target_group.arn
    container_name   = "radius-server"
    container_port   = 1812
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.internal_target_group_radsec.arn
    container_name   = "radius-server"
    container_port   = 2083
  }

  network_configuration {
    subnets = [
      var.vpc.private_subnets[0],
      var.vpc.private_subnets[1]
      ]

    security_groups = [
      aws_security_group.radius_server.id
    ]

    assign_public_ip = false
  }
  lifecycle {
    ignore_changes = ["desired_count"]
  }
}
