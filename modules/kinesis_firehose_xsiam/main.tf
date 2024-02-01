resource "aws_kinesis_firehose_delivery_stream" "xsiam_delivery_stream" {
  name        = "xsiam-delivery-stream-${var.prefix}"
  destination = "http_endpoint"

  http_endpoint_configuration {
    url                = var.http_endpoint
    name               = var.prefix
    access_key         = var.access_key
    buffering_size     = 5
    buffering_interval = 300
    role_arn           = aws_iam_role.xsiam_kinesis_firehose_role.arn
    s3_backup_mode     = "FailedDataOnly"

    cloudwatch_logging_options {
      enabled = true
      log_group_name = "xsiam-delivery-stream-${var.prefix}"
      log_stream_name = "errors"
    }
  }

    s3_configuration {
      role_arn           = aws_iam_role.xsiam_kinesis_firehose_role.arn
      bucket_arn         = aws_s3_bucket.xsiam_firehose_bucket.arn
      buffer_size     = 10
      buffer_interval = 400
      compression_format = "GZIP"
    }

#    request_configuration {
#      content_encoding = "GZIP"
#
#            common_attributes {
#              name  = "testname"
#              value = "testvalue"
#            }
#
#            common_attributes {
#              name  = "testname2"
#              value = "testvalue2"
#            }
#    }
  }

resource "aws_iam_role" "xsiam_kinesis_firehose_role" {

  //name = "kinesis-firehose-role-xsiam"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "firehose.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "xsiam_kinesis_firehose_role_policy" {
  role = aws_iam_role.xsiam_kinesis_firehose_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams",
          "logs:GetLogEvents"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}


resource "aws_iam_role_policy_attachment" "kinesis_role_attachment" {
  policy_arn = aws_iam_policy.s3_kinesis_xsiam_policy.arn
  role       = aws_iam_role.xsiam_kinesis_firehose_role.name

}

resource "aws_iam_policy" "s3_kinesis_xsiam_policy" {

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:*"
        ]
        Effect = "Allow"
        Resource = [
          aws_s3_bucket.xsiam_firehose_bucket.arn,
          "${aws_s3_bucket.xsiam_firehose_bucket.arn}/*"
        ]
      }
    ]
  })
}
