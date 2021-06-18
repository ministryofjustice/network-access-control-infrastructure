resource "aws_s3_bucket" "config_bucket" {
  bucket = "moj-network-authentication-test"
  acl    = "private"
  versioning {
    enabled = true
  }
}
