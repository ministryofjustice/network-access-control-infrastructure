locals {
  privileged = var.enable_packet_capture == "true" ? true : false #parameter store does not support boolean values
}
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
    "privileged": = ${privileged}
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
        "value": "${var.read_replica.name}"
      },
      {
        "name": "DB_USER",
        "value": "${var.read_replica.user}"
      },
      {
        "name": "DB_PASS",
        "value": "${var.read_replica.pass}"
      },
      {
        "name": "DB_HOST",
        "value": "${var.read_replica.host}"
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
        "name": "ENABLE_OCSP",
        "value": "${var.enable_ocsp}"
      },
      {
        "name": "OCSP_OVERRIDE_CERT_URL",
        "value": "${var.ocsp_override_cert_url}"
      },
      {
        "name": "ENABLE_CRL",
        "value": "no"
      },
      {
        "name": "EAP_PRIVATE_KEY_PASSWORD",
        "value": "${var.eap_private_key_password}"
      },
      {
        "name": "MOJO_DNS_IP_1",
        "value": "${var.mojo_dns_ip_1}"
      },
      {
        "name": "MOJO_DNS_IP_2",
        "value": "${var.mojo_dns_ip_2}"
      },
      {
        "name": "RADSEC_PRIVATE_KEY_PASSWORD",
        "value": "${var.radsec_private_key_password}"
      },
      {
        "name": "VERBOSE_LOGGING",
        "value": "${var.radius_verbose_logging}"
      },
      {
        "name": "ENABLE_PACKET_CAPTURE",
        "value": "${var.enable_packet_capture}"
      },
      {
        "name": "PACKET_CAPTURE_DURATION",
        "value": "${var.packet_capture_duration_seconds}"
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
