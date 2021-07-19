resource "aws_ecs_task_definition" "server_task" {
  family                   = "${var.prefix}-server-task"
  task_role_arn            = aws_iam_role.ecs_task_role.arn
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn
  requires_compatibilities = ["FARGATE"]
  cpu                      = "1024"
  memory                   = "2048"
  network_mode             = "awsvpc"

  container_definitions = <<EOF
[
  {
    "portMappings": [
      {
        "hostPort": 1812,
        "containerPort": 1812,
        "protocol": "udp"
      },
      {
        "hostPort": 2083,
        "containerPort": 2083,
        "protocol": "tcp"
      }
    ],
    "essential": true,
    "name": "radius-server",
    "environment": [
      {
        "name": "DB_NAME",
        "value": "${aws_db_instance.radius_server_db.name}"
      },
      {
        "name": "DB_USER",
        "value": "${var.radius_db_username}"
      },
      {
        "name": "DB_PASS",
        "value": "${var.radius_db_password}"
      },
      {
        "name": "DB_HOST",
        "value": "${aws_db_instance.radius_server_db.address}"
      },
      {
        "name": "DB_PORT",
        "value": "3306"
      },
      {
        "name": "RADIUS_CONFIG_BUCKET_NAME",
        "value": "${aws_s3_bucket.config_bucket.id}"
      },
      {
        "name": "RADIUS_CERTIFICATE_BUCKET_NAME",
        "value": "${aws_s3_bucket.certificate_bucket.id}"
      },
      {
        "name": "ECS_ENABLE_CONTAINER_METADATA",
        "value": "true"
      },
      {
        "name": "ENV",
        "value": "${var.env}"
      },
      {
        "name": "OCSP_URL",
        "value": "${var.ocsp_endpoint_ip}:${var.ocsp_endpoint_port}"
      },
      {
        "name": "ENABLE_CRL",
        "value": "no"
      }
    ],
    "image": "${aws_ecr_repository.docker_repository.repository_url}",
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "${aws_cloudwatch_log_group.server_log_group.name}",
        "awslogs-region": "eu-west-2",
        "awslogs-stream-prefix": "eu-west-2-docker-logs"
      }
    },
    "expanded": true
  }, {
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "${aws_cloudwatch_log_group.server_nginx_log_group.name}",
        "awslogs-region": "eu-west-2",
        "awslogs-stream-prefix": "eu-west-2-docker-logs"
      }
    },
    "portMappings": [
      {
        "hostPort": 8000,
        "protocol": "tcp",
        "containerPort": 8000
      }
    ],
    "image": "${aws_ecr_repository.docker_repository_nginx.repository_url}",
    "name": "NGINX"
  }
]
EOF
}
