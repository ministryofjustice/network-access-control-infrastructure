data "aws_caller_identity" "current" {}

resource "aws_cloudwatch_log_group" "admin" {
  name = var.prefix

  retention_in_days = 90

  tags = var.tags
}

resource "aws_ecr_repository" "admin" {
  name = var.prefix

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = var.tags
}

resource "aws_ecr_repository_policy" "admin" {
  repository = aws_ecr_repository.admin.name

  policy = <<EOF
{
    "Version": "2008-10-17",
    "Statement": [
        {
            "Sid": "1",
            "Effect": "Allow",
            "Principal":{
              "AWS": ["${data.aws_caller_identity.current.account_id}","${var.shared_services_account_id}"]
            },
            "Action": [
                "ecr:GetDownloadUrlForLayer",
                "ecr:BatchGetImage",
                "ecr:BatchCheckLayerAvailability",
                "ecr:PutImage",
                "ecr:InitiateLayerUpload",
                "ecr:UploadLayerPart",
                "ecr:CompleteLayerUpload",
                "ecr:DescribeRepositories",
                "ecr:GetRepositoryPolicy",
                "ecr:ListImages",
                "ecr:DeleteRepository",
                "ecr:BatchDeleteImage",
                "ecr:SetRepositoryPolicy",
                "ecr:DeleteRepositoryPolicy"
            ]
        }
    ]
}
EOF
}

resource "aws_ecr_lifecycle_policy" "admin" {
  repository = aws_ecr_repository.admin.name

  policy = <<EOF
{
    "rules": [
        {
            "rulePriority": 1,
            "description": "Expire older versions of untagged images, keeping the latest 15",
            "selection": {
                "tagStatus": "untagged",
                "countType": "imageCountMoreThan",
                "countNumber": 15
            },
            "action": {
                "type": "expire"
            }
        }
    ]
}
EOF
}

locals {
  db_address = var.run_restore_from_backup ? element(aws_db_instance.admin_db_restored.*.address, 0) : aws_db_instance.admin_db.address
  db_name    = var.run_restore_from_backup ? element(aws_db_instance.admin_db_restored.*.name, 0) : aws_db_instance.admin_db.db_name
}

resource "aws_ecs_task_definition" "admin" {
  family                   = "${var.prefix}-task"
  requires_compatibilities = ["FARGATE"]
  task_role_arn            = aws_iam_role.ecs_task_role.arn
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn
  cpu                      = "512"
  memory                   = "2048"
  network_mode             = "awsvpc"

  container_definitions = <<EOF
[
    {
      "portMappings": [
        {
          "hostPort": 3000,
          "containerPort": 3000,
          "protocol": "tcp"
        }
      ],
      "essential": true,
      "name": "admin",
      "environment": [
        {
          "name": "DB_NAME",
          "value": "${local.db_name}"
        },
        {
          "name": "DB_HOST",
          "value": "${local.db_address}"
        },
        {
          "name": "RACK_ENV",
          "value": "production"
        },
        {
          "name": "RAILS_ENV",
          "value": "production"
        },
        {
          "name": "SECRET_KEY_BASE",
          "value": "${var.secret_key_base}"
        },
        {
          "name": "RAILS_LOG_TO_STDOUT",
          "value": "1"
        },
        {
          "name": "RAILS_SERVE_STATIC_FILES",
          "value": "1"
        },
        {
          "name": "COGNITO_USER_POOL_SITE",
          "value": "https://${var.cognito_user_pool_domain}.auth.${var.region}.amazoncognito.com"
        },
        {
          "name": "RADIUS_CLUSTER_NAME",
          "value": "${var.radius_cluster_name}"
        },
        {
          "name": "RADIUS_SERVICE_NAME",
          "value": "${var.radius_service_name}"
        },
        {
          "name": "RADIUS_INTERNAL_SERVICE_NAME",
          "value": "${var.radius_internal_service_name}"
        },
        {
          "name": "RADIUS_CONFIG_BUCKET_NAME",
          "value": "${var.radius_config_bucket_name}"
        },
        {
          "name": "RADIUS_CERTIFICATE_BUCKET_NAME",
          "value": "${var.radius_certificate_bucket_name}"
        },
        {
          "name": "CLOUDWATCH_LINK",
          "value": "${var.cloudwatch_link}"
        },
        {
          "name": "GRAFANA_DASHBOARD_LINK",
          "value": "${var.grafana_dashboard_link}"
        },
        {
          "name": "SERVER_IPS",
          "value": "${var.server_ips}"
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
          "name": "SENTRY_DSN",
          "valueFrom": "${var.secret_arns["moj_network_access_control_env_admin_sentry_dsn"]}"
        },
        {
          "name": "EAP_SERVER_PRIVATE_KEY_PASSPHRASE",
          "valueFrom": "${var.secret_arns["moj_network_access_control_env_eap_private_key_password"]}"
        },
        {
          "name": "RADSEC_SERVER_PRIVATE_KEY_PASSPHRASE",
          "valueFrom": "${var.secret_arns["moj_network_access_control_env_radsec_private_key_password"]}"
        },
        {
          "name": "COGNITO_USER_POOL_ID",
          "valueFrom": "${var.secret_arns["moj_network_access_control_env_cognito_userpool_id"]}"
        },
        {
          "name": "COGNITO_CLIENT_SECRET",
          "valueFrom": "${var.secret_arns["moj_network_access_control_env_cognito_client_secret"]}"
        },
        {
          "name": "COGNITO_CLIENT_ID",
          "valueFrom": "${var.secret_arns["moj_network_access_control_env_cognito_client_id"]}"
        }
    ],
      "image": "${aws_ecr_repository.admin.repository_url}",
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "${aws_cloudwatch_log_group.admin.name}",
          "awslogs-region": "${var.region}",
          "awslogs-stream-prefix": "${var.prefix}-docker-logs"
        }
      },
      "expanded": true
    }
]
EOF

  tags = var.tags
}

resource "aws_ecs_task_definition" "admin_background_worker" {
  family                   = "${var.prefix}-task"
  requires_compatibilities = ["FARGATE"]
  task_role_arn            = aws_iam_role.ecs_task_role.arn
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn
  cpu                      = "512"
  memory                   = "2048"

  network_mode = "awsvpc"

  container_definitions = <<EOF
[
    {
      "essential": true,
      "name": "admin",
      "command": ["bundle", "exec", "rake", "jobs:work"],
      "environment": [
        {
          "name": "DB_NAME",
          "value": "${aws_db_instance.admin_db.db_name}"
        },{
          "name": "DB_HOST",
          "value": "${aws_db_instance.admin_db.address}"
        },{
          "name": "RACK_ENV",
          "value": "production"
        },{
          "name": "RAILS_ENV",
          "value": "production"
        },{
          "name": "SECRET_KEY_BASE",
          "value": "${var.secret_key_base}"
        },{
          "name": "RAILS_LOG_TO_STDOUT",
          "value": "1"
        },{
          "name": "RAILS_SERVE_STATIC_FILES",
          "value": "1"
        },
        {
          "name": "COGNITO_USER_POOL_SITE",
          "value": "https://${var.cognito_user_pool_domain}.auth.${var.region}.amazoncognito.com"
        },
        {
          "name": "RADIUS_CLUSTER_NAME",
          "value": "${var.radius_cluster_name}"
        },
        {
          "name": "RADIUS_SERVICE_NAME",
          "value": "${var.radius_service_name}"
        },
        {
          "name": "RADIUS_INTERNAL_SERVICE_NAME",
          "value": "${var.radius_internal_service_name}"
        },
        {
          "name": "RADIUS_CONFIG_BUCKET_NAME",
          "value": "${var.radius_config_bucket_name}"
        },
        {
          "name": "RADIUS_CERTIFICATE_BUCKET_NAME",
          "value": "${var.radius_certificate_bucket_name}"
        },
        {
          "name": "CLOUDWATCH_LINK",
          "value": "${var.cloudwatch_link}"
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
          "name": "SENTRY_DSN",
          "valueFrom": "${var.secret_arns["moj_network_access_control_env_admin_sentry_dsn"]}"
        },
        {
          "name": "COGNITO_USER_POOL_ID",
          "valueFrom": "${var.secret_arns["moj_network_access_control_env_cognito_userpool_id"]}"
        },
        {
          "name": "COGNITO_CLIENT_SECRET",
          "valueFrom": "${var.secret_arns["moj_network_access_control_env_cognito_client_secret"]}"
        },
        {
          "name": "COGNITO_CLIENT_ID",
          "valueFrom": "${var.secret_arns["moj_network_access_control_env_cognito_client_id"]}"
        }
    ],
      "image": "${aws_ecr_repository.admin.repository_url}",
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "${aws_cloudwatch_log_group.admin.name}",
          "awslogs-region": "${var.region}",
          "awslogs-stream-prefix": "${var.prefix}-docker-logs"
        }
      },
      "expanded": true
    }
]
EOF

  tags = var.tags
}

resource "aws_ecs_service" "admin_background_worker" {
  name            = "admin-background-workers"
  cluster         = var.radius_cluster_id
  task_definition = aws_ecs_task_definition.admin_background_worker.arn
  desired_count   = 3
  launch_type     = "FARGATE"

  network_configuration {
    subnets = var.vpc.public_subnets

    security_groups = [
      aws_security_group.admin_ecs.id
    ]

    assign_public_ip = true
  }

  lifecycle {
    ignore_changes = [
      desired_count
    ]
  }

  tags = var.tags
}

resource "aws_ecs_service" "admin" {
  depends_on      = [aws_alb_listener.alb_listener]
  name            = "admin"
  cluster         = var.radius_cluster_id
  task_definition = aws_ecs_task_definition.admin.arn
  desired_count   = 3
  launch_type     = "FARGATE"

  load_balancer {
    target_group_arn = aws_alb_target_group.admin.arn
    container_name   = "admin"
    container_port   = "3000"
  }

  network_configuration {
    subnets = var.vpc.public_subnets

    security_groups = [
      aws_security_group.admin_ecs.id
    ]

    assign_public_ip = true
  }

  lifecycle {
    ignore_changes = [
      desired_count
    ]
  }

  tags = var.tags
}

resource "aws_alb_target_group" "admin" {
  depends_on           = [aws_lb.admin_alb]
  name                 = "${var.short_prefix}-admin"
  port                 = "3000"
  protocol             = "HTTP"
  vpc_id               = var.vpc.id
  target_type          = "ip"
  deregistration_delay = 10

  health_check {
    healthy_threshold   = 3
    unhealthy_threshold = 10
    timeout             = 5
    interval            = 10
    path                = "/healthcheck"
  }

  tags = var.tags

  lifecycle {
    create_before_destroy = true
  }
}
