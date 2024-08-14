locals {
  # radius_user = var.enable_packet_capture == "true" ? "root" : "freerad"
  radius_user = "root"
}

resource "aws_ecs_task_definition" "server_task" {
  family                   = "${var.prefix}-server-task"
  task_role_arn            = aws_iam_role.ecs_task_role.arn
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn
  requires_compatibilities = ["FARGATE"]
  cpu                      = "1024"
  memory                   = "2048"
  network_mode             = "awsvpc"

  tags = var.tags

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
    "user": "${local.radius_user}",
    "environment": [
      {
        "name": "DB_NAME",
        "value": "${var.read_replica.name}"
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
        "name": "MOJO_DNS_IP_1",
        "value": "${var.mojo_dns_ip_1}"
      },
      {
        "name": "MOJO_DNS_IP_2",
        "value": "${var.mojo_dns_ip_2}"
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
      "secrets": [
        {
          "name": "DB_USER",
          "valueFrom": "${var.secret_arns["moj_network_access_control_env_admin_db"]}:username::"
        },
        {
          "name": "DB_PASS",
          "valueFrom": "${var.secret_arns["moj_network_access_control_env_admin_db"]}:password::"
        },
        {
          "name": "EAP_SERVER_PRIVATE_KEY_PASSPHRASE",
          "valueFrom": "${var.secret_arns["moj_network_access_control_env_eap_private_key_password"]}"
        },
        {
          "name": "RADSEC_SERVER_PRIVATE_KEY_PASSPHRASE",
          "valueFrom": "${var.secret_arns["moj_network_access_control_env_radsec_private_key_password"]}"
        }
    ],
    "image": "${aws_ecr_repository.radius.repository_url}",
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
    "image": "${aws_ecr_repository.nginx.repository_url}",
    "name": "NGINX"
  }
]
EOF
}
