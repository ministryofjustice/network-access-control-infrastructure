resource "aws_security_group" "performance_testing_instance" {
  name        = "performance-testing-instance"
  description = "Allow SSH into Performance Testing instance"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
      from_port = 1812
      to_port   = 1812
      protocol  = "udp"
      cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
      from_port = 1814
      to_port   = 1814
      protocol  = "udp"
      cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
      from_port = 2083
      to_port   = 2083
      protocol  = "tcp"
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

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["86.171.222.234/32"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["176.26.170.123/32"]
  }
  ingress {
      from_port = 1812
      to_port   = 1812
      protocol  = "udp"
      cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
      from_port = 1814
      to_port   = 1814
      protocol  = "udp"
      cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
      from_port = 2083
      to_port   = 2083
      protocol  = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
  }

}