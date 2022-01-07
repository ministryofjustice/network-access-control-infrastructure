resource "aws_instance" "performance_testing_instance" {
  ami           = "ami-07438ed9014cde68f"
  instance_type = "t4g.medium"
  count         = 18

  vpc_security_group_ids = [
    aws_security_group.performance_testing_instance.id
  ]

  subnet_id                   = var.subnets[0]
  key_name                    = aws_key_pair.performance_testing_public_key_pair.key_name
  monitoring                  = true
  associate_public_ip_address = true
  iam_instance_profile = aws_iam_instance_profile.ec2_perf_test_profile.name
  instance_initiated_shutdown_behavior = "terminate"
  user_data = data.template_cloudinit_config.config.rendered

  tags = {
    Name = "MoJ Authentication Performance-${count.index}"
  }
}

data "template_file" "client" {
  template = file("./modules/performance_testing/user_data.sh")
  vars = {
    s3_bucket_name = aws_s3_bucket.config_bucket.id
  }
}

data "template_cloudinit_config" "config" {
  gzip          = false
  base64_encode = false
  #first part of local config file
  part {
    content_type = "text/x-shellscript"
    content      = data.template_file.client.rendered
  }
}
