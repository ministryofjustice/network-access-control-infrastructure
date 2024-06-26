resource "aws_lb" "load_balancer" {
  name                             = "nac-radius-lb-${var.short_prefix}"
  load_balancer_type               = "network"
  internal                         = false
  enable_cross_zone_load_balancing = true
  security_groups                  = terraform.workspace == "production" ? [aws_security_group.nlb_public_production.id, aws_security_group.nlb_public.id] : [aws_security_group.nlb_public.id]
  access_logs {
    bucket  = aws_s3_bucket.lb_log_bucket.bucket
    enabled = true
  }

  subnet_mapping {
    subnet_id     = var.vpc.public_subnets[0]
    allocation_id = aws_eip.nac_eu_west_2a.id
  }

  subnet_mapping {
    subnet_id     = var.vpc.public_subnets[1]
    allocation_id = aws_eip.nac_eu_west_2b.id
  }

  subnet_mapping {
    subnet_id     = var.vpc.public_subnets[2]
    allocation_id = aws_eip.nac_eu_west_2c.id
  }

  tags = var.tags

  enable_deletion_protection = var.enable_nlb_deletion_protection
}

resource "aws_eip" "nac_eu_west_2a" {
  vpc              = true
  public_ipv4_pool = var.byoip_pool_id
  tags             = var.tags
}

resource "aws_eip" "nac_eu_west_2b" {
  vpc              = true
  public_ipv4_pool = var.byoip_pool_id
  tags             = var.tags
}

resource "aws_eip" "nac_eu_west_2c" {
  vpc              = true
  public_ipv4_pool = var.byoip_pool_id
  tags             = var.tags
}

resource "aws_lb_listener" "udp" {
  load_balancer_arn = aws_lb.load_balancer.arn
  port              = "1812"
  protocol          = "UDP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target_group.arn
  }

  tags = var.tags
}

resource "aws_lb_listener" "tcp" {
  load_balancer_arn = aws_lb.load_balancer.arn
  port              = "2083"
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target_group_radsec.arn
  }

  tags = var.tags
}

resource "aws_lb_target_group" "target_group" {
  name                 = var.prefix
  protocol             = "TCP_UDP"
  vpc_id               = var.vpc.id
  port                 = "1812"
  target_type          = "ip"
  deregistration_delay = 300
  preserve_client_ip   = true

  health_check {
    port     = 8000
    protocol = "TCP"
  }
  depends_on = [aws_lb.load_balancer]

  tags = var.tags
}

resource "aws_lb_target_group" "target_group_radsec" {
  name                 = "${var.prefix}-radsec"
  protocol             = "TCP"
  vpc_id               = var.vpc.id
  port                 = "2083"
  target_type          = "ip"
  deregistration_delay = 300
  preserve_client_ip   = true

  health_check {
    port     = 8000
    protocol = "TCP"
  }
  depends_on = [aws_lb.load_balancer]
  tags       = var.tags
}

resource "aws_s3_bucket" "lb_log_bucket" {
  bucket = "${var.prefix}-lb-log-bucket"

  tags = var.tags
}

resource "aws_s3_bucket_lifecycle_configuration" "lb_log_bucket_lifecycle_policy" {
  bucket = aws_s3_bucket.lb_log_bucket.id

  rule {
    id = "30_day_retention_lb_log_bucket-1"
    expiration {
      days = 30
    }
    status = "Enabled"
  }
}

resource "aws_s3_bucket_policy" "lb_log_bucket_policy" {
  bucket = aws_s3_bucket.lb_log_bucket.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Id": "ConfigFetch",
  "Statement": [
    {
      "Sid": "AWSLogDeliveryWrite",
      "Effect": "Allow",
      "Principal": {
        "Service": "delivery.logs.amazonaws.com"
      },
      "Action": "s3:PutObject",
      "Resource": "${aws_s3_bucket.lb_log_bucket.arn}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"
    },
    {
      "Sid": "AWSLogDeliveryAclCheck",
      "Effect": "Allow",
      "Principal": {
        "Service": "delivery.logs.amazonaws.com"
      },
      "Action": "s3:GetBucketAcl",
      "Resource": "${aws_s3_bucket.lb_log_bucket.arn}"
    }
  ]
}
EOF
}

resource "aws_s3_bucket_public_access_block" "lb_log_bucket_public_block" {
  bucket = aws_s3_bucket.lb_log_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_kms_key" "lb_log_bucket_key" {
  description             = "This key is used to encrypt bucket objects"
  deletion_window_in_days = 10
  enable_key_rotation     = true
}

//Security group for PUBLIC NLB

variable "ingress_rules" {
  type = list(object({
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
    description = string
  }))
  default = [
    {
      from_port   = 8000
      to_port     = 8000
      protocol    = "tcp"
      cidr_blocks = ["10.180.108.0/22"]
      description = "Allow load balancer health checks"
    },
    {
      from_port   = 2083
      to_port     = 2083
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      description = " Allow inbound RADSEC traffic to the Radius server"
    },
    {
      from_port   = 1812
      to_port     = 1812
      protocol    = "udp"
      cidr_blocks = ["0.0.0.0/0"]
      description = "Allow inbound EAP traffic to the Radius server"
    }
  ]
}

variable "egress_rules" {
  type = list(object({
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
    description = string
  }))
  default = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
      description = "Allow all outbound traffic"
    }
  ]
}

resource "aws_security_group" "nlb_public" {
  name   = "${var.prefix}-nlb-public"
  vpc_id = var.vpc.id

  tags = merge(var.tags, {
    Name = "${var.prefix}-nlb-public"
  })

  dynamic "ingress" {
    for_each = var.ingress_rules

    content {
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
      description = ingress.value.description
    }
  }

  dynamic "egress" {
    for_each = var.egress_rules

    content {
      from_port   = egress.value.from_port
      to_port     = egress.value.to_port
      protocol    = egress.value.protocol
      cidr_blocks = egress.value.cidr_blocks
      description = egress.value.description
    }
  }
}
variable "ingress_rules_production" {
  type = list(object({
    from_port   = number
    to_port     = number
    protocol    = string
    description = string
  }))
  default = [
    {
      from_port   = 2083
      to_port     = 2083
      protocol    = "tcp"
      description = " Allow inbound RADSEC traffic to the Radius server"
    },
    {
      from_port   = 1812
      to_port     = 1812
      protocol    = "udp"
      description = "Allow inbound EAP traffic to the Radius server"
    }
  ]
}

resource "aws_security_group" "nlb_public_production" {
  name   = "${var.prefix}-nlb-public_production"
  vpc_id = var.vpc.id

  tags = merge(var.tags, {
    Name = "${var.prefix}-nlb-public_production"
  })

  dynamic "ingress" {
    for_each = var.ingress_rules_production

    content {
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      protocol    = ingress.value.protocol
      cidr_blocks = var.allowed_ips
      description = ingress.value.description
    }
  }

  dynamic "egress" {
    for_each = var.egress_rules

    content {
      from_port   = egress.value.from_port
      to_port     = egress.value.to_port
      protocol    = egress.value.protocol
      cidr_blocks = egress.value.cidr_blocks
      description = egress.value.description
    }

  }
}

