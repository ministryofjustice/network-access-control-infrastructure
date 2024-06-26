resource "aws_s3_bucket" "certificate_bucket" {
  bucket = "${var.prefix}-certificate-bucket"

  tags = var.tags
}

resource "aws_s3_bucket_server_side_encryption_configuration" "cert_bucket_encryption" {
  bucket = aws_s3_bucket.certificate_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.certificate_bucket_key.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_logging" "certificate_bucket_logging" {
  bucket = aws_s3_bucket.certificate_bucket.id

  target_bucket = aws_s3_bucket.certificate_bucket_logs.id
  target_prefix = "log/"
}

data "template_file" "certificate_bucket_policy" {
  template = file("${path.module}/policies/bucket_policy.json")

  vars = {
    bucket_arn        = aws_s3_bucket.certificate_bucket.arn,
    ecs_task_role_arn = aws_iam_role.ecs_task_role.arn
  }
}

resource "aws_s3_bucket_policy" "certificate_bucket_policy" {
  bucket = aws_s3_bucket.certificate_bucket.id

  policy = data.template_file.certificate_bucket_policy.rendered
}

resource "aws_s3_bucket_public_access_block" "certificate_bucket_public_block" {
  bucket = aws_s3_bucket.certificate_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_kms_key" "certificate_bucket_key" {
  description             = "This key is used to encrypt bucket objects"
  deletion_window_in_days = 10
  enable_key_rotation     = true
}

resource "aws_s3_bucket" "certificate_bucket_logs" {
  bucket = "${var.prefix}-certificate-bucket-logs"

  tags = var.tags
}

resource "aws_s3_bucket_lifecycle_configuration" "cert_log_bucket_lifecycle_policy" {
  bucket = aws_s3_bucket.certificate_bucket_logs.id

  rule {
    id = "30_day_retention_certificate_bucket_logs-1"
    expiration {
      days = 30
    }
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "certificate_log_bucket_public_block" {
  bucket = aws_s3_bucket.certificate_bucket_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
