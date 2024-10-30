resource "aws_iam_role" "ecs_task_role" {
  name = "${var.prefix}-ecs-task-role"

  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json

  tags = var.tags
}

resource "aws_iam_role" "ecs_execution_role" {
  name = "${var.prefix}-ecs-execution-role"

  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json

  tags = var.tags
}

resource "aws_iam_role_policy" "ecs_task_policy" {
  name = "${var.prefix}-ecs-task-policy"
  role = aws_iam_role.ecs_task_role.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "kms:GenerateDataKey",
        "kms:Encrypt",
        "kms:Decrypt"
      ],
      "Resource": ["*"]
    },{
      "Effect": "Allow",
      "Action": [
        "s3:ListBucket",
        "s3:GetObject"
      ],
      "Resource": ["*"]
    },{
      "Effect": "Allow",
      "Action": [
        "cloudwatch:PutMetricData"
      ],
      "Resource": ["*"]
    }
  ]
}
EOF
}

data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_policy_attachment" {
  for_each = toset([
    "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy",
    "arn:aws:iam::aws:policy/AmazonSSMReadOnlyAccess"
  ])

  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = each.value
}

resource "aws_iam_policy" "secrets_manager_read_only" {
  name        = "SecretsManagerReadOnly-${var.prefix}"
  path        = "/"
  description = "allow all secrets to be read in secrets manager by ecs"


  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "secretsmanager:GetResourcePolicy",
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret",
          "secretsmanager:ListSecretVersionIds",
          "secretsmanager:ListSecrets"
        ],
        "Resource" : values(var.secret_arns)
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_policy_attachment_sm" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = aws_iam_policy.secrets_manager_read_only.arn
}
