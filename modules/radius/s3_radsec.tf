resource "aws_s3_bucket" "radsec_certificate_bucket" {
  bucket = "${var.prefix}-radsec-certificate-bucket"
  acl    = "private"
  versioning {
    enabled = true
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = aws_kms_key.radsec_bucket_key.arn
        sse_algorithm     = "aws:kms"
      }
    }
  }
}

data "template_file" "radsec_bucket_policy" {
  template = file("${path.module}/policies/bucket_policy.json")

  vars = {
    bucket_arn = aws_s3_bucket.radsec_certificate_bucket.arn,
    ecs_task_role_arn = aws_iam_role.ecs_task_role.arn
  }
}

resource "aws_s3_bucket_policy" "radsec_bucket_policy" {
  bucket = aws_s3_bucket.radsec_certificate_bucket.id

  policy = data.template_file.radsec_bucket_policy.rendered
}

resource "aws_s3_bucket_public_access_block" "radsec_bucket_public_block" {
  bucket = aws_s3_bucket.radsec_certificate_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_kms_key" "radsec_bucket_key" {
  description             = "This key is used to encrypt bucket objects"
  deletion_window_in_days = 10
  enable_key_rotation     = true
}

