resource "tls_private_key" "ec2" {
  algorithm = "RSA"
}

resource "aws_key_pair" "performance_testing_public_key_pair" {
  key_name   = "performance-testing"
  public_key = tls_private_key.ec2.public_key_openssh
}
