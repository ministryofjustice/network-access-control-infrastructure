resource "aws_iam_instance_profile" "ec2_perf_test_profile" {
  name = "${var.prefix}-profile"
  role = aws_iam_role.moj_auth_poc_role.name
}

resource "aws_iam_role" "moj_auth_poc_role" {
  name = "${var.prefix}-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
}

resource "aws_iam_role_policy" "ec2_task_policy" {
  name = "${var.prefix}-ec2-task-policy"
  role = aws_iam_role.moj_auth_poc_role.id

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
        "s3:GetObject"
      ],
      "Resource": ["*"]
    },{
      "Effect": "Allow",
      "Action": [
        "s3:ListBucket"
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
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}
