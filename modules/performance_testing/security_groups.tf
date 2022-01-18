resource "aws_security_group" "performance_testing_instance" {
  name        = "performance-testing-instance"
  description = "Performance testing instance"
  vpc_id      = var.vpc_id

  egress {
      from_port = 1812
      to_port   = 1812
      protocol  = "udp"
      cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
