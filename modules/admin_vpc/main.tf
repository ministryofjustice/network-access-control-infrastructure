module "vpc" {
  source = "../vpc_hashicorp"
  # source  = "terraform-aws-modules/vpc/aws"
  # version = "3.0.0"
  name    = "${var.prefix}-vpc"

  cidr                 = var.cidr_block
  enable_nat_gateway   = true
  enable_dns_hostnames = true
  enable_dns_support   = true

  azs = [
    "${var.region}a",
    "${var.region}b",
    "${var.region}c"
  ]

  public_subnets = [
    cidrsubnet(var.cidr_block, var.cidr_block_new_bits, 1),
    cidrsubnet(var.cidr_block, var.cidr_block_new_bits, 2),
    cidrsubnet(var.cidr_block, var.cidr_block_new_bits, 3)
  ]

  private_subnets = [
    cidrsubnet(var.cidr_block, var.cidr_block_new_bits, 4),
    cidrsubnet(var.cidr_block, var.cidr_block_new_bits, 5),
    cidrsubnet(var.cidr_block, var.cidr_block_new_bits, 6)
  ]

  manage_default_security_group  = true
  default_security_group_ingress = []
  default_security_group_egress  = []

  tags = merge(var.tags, { "Name" = var.prefix })
}
