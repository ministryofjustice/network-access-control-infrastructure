resource "aws_s3_bucket" "xsiam_firehose_bucket" {
  bucket = "xsiam-firehose-${var.prefix}"
  tags   = var.tags
}

resource "aws_s3_bucket_public_access_block" "xsiam_firehose_bucket_block_public_access" {
  bucket = aws_s3_bucket.xsiam_firehose_bucket.bucket

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
