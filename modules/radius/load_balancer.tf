resource "aws_lb" "load_balancer" {
  name                             = "nac-radius-lb-${var.short_prefix}"
  load_balancer_type               = "network"
  internal                         = false
  enable_cross_zone_load_balancing = true
  access_logs {
    bucket  = aws_s3_bucket.lb_log_bucket.bucket
    enabled = true
  }

  subnet_mapping {
    subnet_id = var.vpc.public_subnets[0]
    allocation_id = aws_eip.nac_eu_west_2a.id
  }

  subnet_mapping {
    subnet_id = var.vpc.public_subnets[1]
    allocation_id = aws_eip.nac_eu_west_2b.id
  }

  subnet_mapping {
    subnet_id = var.vpc.public_subnets[2]
    allocation_id = aws_eip.nac_eu_west_2c.id
  }

  enable_deletion_protection = var.enable_nlb_deletion_protection
}

resource "aws_eip" "nac_eu_west_2a" {
  vpc              = true
  public_ipv4_pool = var.byoip_pool_id
}

resource "aws_eip" "nac_eu_west_2b" {
  vpc              = true
  public_ipv4_pool = var.byoip_pool_id
}

resource "aws_eip" "nac_eu_west_2c" {
  vpc              = true
  public_ipv4_pool = var.byoip_pool_id
}

resource "aws_lb_listener" "udp" {
  load_balancer_arn = aws_lb.load_balancer.arn
  port              = "1812"
  protocol          = "UDP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target_group.arn
  }
}

resource "aws_lb_listener" "tcp" {
  load_balancer_arn = aws_lb.load_balancer.arn
  port              = "2083"
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target_group_radsec.arn
  }
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
}


resource "aws_s3_bucket" "lb_log_bucket" {
  bucket = "${var.prefix}-lb-log-bucket"
  acl    = "private"
  versioning {
    enabled = true
  }
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = aws_kms_key.lb_log_bucket_key.arn
        sse_algorithm     = "aws:kms"
      }
    }
  }
  lifecycle_rule {
    id      = "30_day_retention_lb_bucket_logs"
    enabled = true
    expiration {
        days = 30
    }
  }
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

