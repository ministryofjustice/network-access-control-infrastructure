// endpoints required for session manager

// endpoint required for bastions and ecs task get ssm parameters & secrets manager secrets

resource "aws_vpc_endpoint" "secrets" {
  vpc_id              = module.vpc.vpc_id
  subnet_ids          = module.vpc.public_subnets
  service_name        = "com.amazonaws.${var.region}.secretsmanager"
  vpc_endpoint_type   = "Interface"
  security_group_ids  = [aws_security_group.endpoints.id]
  private_dns_enabled = true
  tags                = var.tags
  depends_on          = [aws_security_group.endpoints]
}

resource "aws_vpc_endpoint" "ssm" {
  count               = 1 #var.ssm_session_manager_endpoints ? 1 : 0
  vpc_id              = module.vpc.vpc_id
  subnet_ids          = module.vpc.private_subnets
  service_name        = "com.amazonaws.${var.region}.ssm"
  vpc_endpoint_type   = "Interface"
  security_group_ids  = [aws_security_group.endpoints.id]
  private_dns_enabled = true
  tags                = var.tags
  depends_on          = [aws_security_group.endpoints]
}

resource "aws_vpc_endpoint" "ssmmessages" {
  count               = 1 #var.ssm_session_manager_endpoints ? 1 : 0
  vpc_id              = module.vpc.vpc_id
  subnet_ids          = module.vpc.private_subnets
  service_name        = "com.amazonaws.${var.region}.ssmmessages"
  vpc_endpoint_type   = "Interface"
  security_group_ids  = [aws_security_group.endpoints.id]
  private_dns_enabled = true
  tags                = var.tags
  depends_on          = [aws_security_group.endpoints]
}

resource "aws_vpc_endpoint" "ec2messages" {
  count               = var.ssm_session_manager_endpoints ? 1 : 0
  vpc_id              = module.vpc.vpc_id
  subnet_ids          = module.vpc.private_subnets
  service_name        = "com.amazonaws.${var.region}.ec2messages"
  vpc_endpoint_type   = "Interface"
  security_group_ids  = [aws_security_group.endpoints.id]
  private_dns_enabled = true
  tags                = var.tags
  depends_on          = [aws_security_group.endpoints]
}

resource "aws_vpc_endpoint" "kms" {
  count               = var.ssm_session_manager_endpoints ? 1 : 0
  vpc_id              = module.vpc.vpc_id
  subnet_ids          = module.vpc.private_subnets
  service_name        = "com.amazonaws.${var.region}.kms"
  vpc_endpoint_type   = "Interface"
  security_group_ids  = [aws_security_group.endpoints.id]
  private_dns_enabled = true
  tags                = var.tags
  depends_on          = [aws_security_group.endpoints]
}

resource "aws_vpc_endpoint" "sts" {
  count               = 1 #var.ssm_session_manager_endpoints ? 1 : 0
  vpc_id              = module.vpc.vpc_id
  subnet_ids          = module.vpc.public_subnets
  service_name        = "com.amazonaws.${var.region}.sts"
  vpc_endpoint_type   = "Interface"
  security_group_ids  = [aws_security_group.endpoints.id]
  private_dns_enabled = true
  tags                = var.tags
  depends_on          = [aws_security_group.endpoints]
}

############## VPC Endpoints ##############

resource "aws_vpc_endpoint" "s3" {
  vpc_id            = module.vpc.vpc_id
  service_name      = "com.amazonaws.${var.region}.s3"
  vpc_endpoint_type = "Gateway"
  tags              = merge(var.tags, { "Name" : "${var.prefix}-s3" })
}

resource "aws_vpc_endpoint_route_table_association" "private_s3" {
  for_each        = toset(module.vpc.private_route_table_ids)
  route_table_id  = each.key
  vpc_endpoint_id = aws_vpc_endpoint.s3.id
}

resource "aws_vpc_endpoint_route_table_association" "public_s3" {
  route_table_id  = local.public_table_id
  vpc_endpoint_id = aws_vpc_endpoint.s3.id
}

resource "aws_vpc_endpoint" "rds" {
  vpc_id              = module.vpc.vpc_id
  subnet_ids          = module.vpc.private_subnets
  service_name        = "com.amazonaws.${var.region}.rds"
  security_group_ids  = [aws_security_group.endpoints.id]
  private_dns_enabled = true
  vpc_endpoint_type   = "Interface"
  tags                = merge(var.tags, { "Name" : "${var.prefix}-rds" })
  depends_on          = [aws_security_group.endpoints]
}

resource "aws_vpc_endpoint" "ecr_api" {
  vpc_id              = module.vpc.vpc_id
  subnet_ids          = module.vpc.private_subnets
  service_name        = "com.amazonaws.${var.region}.ecr.api"
  security_group_ids  = [aws_security_group.endpoints.id]
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  tags                = merge(var.tags, { "Name" : "${var.prefix}-ecr-api" })
  depends_on          = [aws_security_group.endpoints]
}

resource "aws_vpc_endpoint" "ecr_dkr" {
  vpc_id              = module.vpc.vpc_id
  subnet_ids          = module.vpc.private_subnets
  service_name        = "com.amazonaws.${var.region}.ecr.dkr"
  security_group_ids  = [aws_security_group.endpoints.id]
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  tags                = merge(var.tags, { "Name" : "${var.prefix}-ecr-dkr" })
  depends_on          = [aws_security_group.endpoints]
}

resource "aws_vpc_endpoint" "logs" {
  vpc_id              = module.vpc.vpc_id
  subnet_ids          = module.vpc.private_subnets
  service_name        = "com.amazonaws.${var.region}.logs"
  security_group_ids  = [aws_security_group.endpoints.id]
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  tags                = merge(var.tags, { "Name" : "${var.prefix}-logs" })
  depends_on          = [aws_security_group.endpoints]
}

resource "aws_vpc_endpoint" "monitoring" {
  vpc_id              = module.vpc.vpc_id
  subnet_ids          = module.vpc.private_subnets
  service_name        = "com.amazonaws.${var.region}.monitoring"
  vpc_endpoint_type   = "Interface"
  security_group_ids  = [aws_security_group.endpoints.id]
  private_dns_enabled = true
  tags                = merge(var.tags, { "Name" : "${var.prefix}-monitoring" })
  depends_on          = [aws_security_group.endpoints]
}
