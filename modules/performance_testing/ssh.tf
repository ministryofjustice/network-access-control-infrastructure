resource "tls_private_key" "ec2" {
  algorithm = "RSA"
}
resource "aws_key_pair" "performance_testing_public_key_pair" {
  key_name   = "${var.prefix}-performance-testing"
  public_key = tls_private_key.ec2.public_key_openssh
}

resource "aws_ssm_parameter" "instance_private_key" {
  name        = "/network-access-control/${var.prefix}/ec2/key"
  type        = "SecureString"
  value       = tls_private_key.ec2.private_key_pem
  overwrite   = true
  description = "master ssh key for env ${var.prefix}"
}

