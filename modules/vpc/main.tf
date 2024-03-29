resource "aws_security_group" "endpoints" {
  name   = "${var.prefix}-endpoints"
  vpc_id = module.vpc.vpc_id

  ingress {
    protocol    = "tcp"
    from_port   = 443
    to_port     = 443
    cidr_blocks = [var.cidr_block]
  }

  egress {
    protocol    = "tcp"
    from_port   = 443
    to_port     = 443
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = var.tags
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "2.78.0"
  name    = "${var.prefix}-vpc"

  cidr = var.cidr_block

  azs = [
    "eu-west-2a",
    "eu-west-2b",
    "eu-west-2c"
  ]
  enable_ecr_dkr_endpoint              = true
  enable_ecr_api_endpoint              = true
  ecr_api_endpoint_security_group_ids  = [aws_security_group.endpoints.id]
  ecr_dkr_endpoint_private_dns_enabled = true
  ecr_api_endpoint_private_dns_enabled = true
  ecr_dkr_endpoint_security_group_ids  = [aws_security_group.endpoints.id]

  enable_monitoring_endpoint              = true
  monitoring_endpoint_private_dns_enabled = true
  monitoring_endpoint_security_group_ids  = [aws_security_group.endpoints.id]
  enable_dhcp_options                     = true
  dhcp_options_domain_name_servers        = ["AmazonProvidedDNS"]

  enable_rds_endpoint              = true
  rds_endpoint_private_dns_enabled = true
  rds_endpoint_security_group_ids  = [aws_security_group.endpoints.id]
  enable_dns_hostnames             = true
  enable_s3_endpoint               = true

  enable_logs_endpoint              = true
  logs_endpoint_private_dns_enabled = true
  logs_endpoint_security_group_ids  = [aws_security_group.endpoints.id]
  enable_dns_support                = true
  manage_default_security_group     = true
  default_security_group_ingress    = []
  default_security_group_egress     = []
  private_subnets = [
    cidrsubnet(var.cidr_block, var.cidr_block_new_bits, 0),
    cidrsubnet(var.cidr_block, var.cidr_block_new_bits, 2),
    cidrsubnet(var.cidr_block, var.cidr_block_new_bits, 4)
  ]

  public_subnets = [
    cidrsubnet(var.cidr_block, var.cidr_block_new_bits, 1),
    cidrsubnet(var.cidr_block, var.cidr_block_new_bits, 3),
    cidrsubnet(var.cidr_block, var.cidr_block_new_bits, 5),
  ]

  tags = var.tags
}
