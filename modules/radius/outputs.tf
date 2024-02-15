output "ecr" {
  value = {
    repository_url       = aws_ecr_repository.radius.repository_url
    registry_id          = aws_ecr_repository.radius.registry_id
    nginx_repository_url = aws_ecr_repository.nginx.repository_url
  }
}

output "ecs" {
  value = {
    service_arn           = aws_ecs_service.service.id
    service_name          = aws_ecs_service.service.name
    cluster_name          = aws_ecs_cluster.server_cluster.name
    cluster_id            = aws_ecs_cluster.server_cluster.id
    task_definition_name  = aws_ecs_task_definition.server_task.id
    internal_service_name = aws_ecs_service.internal_service.name
    internal_service_arn  = aws_ecs_service.internal_service.id
  }
}

output "load_balancer" {
  value = {
    nac_eu_west_2a_ip_address = aws_eip.nac_eu_west_2a.public_ip
    nac_eu_west_2b_ip_address = aws_eip.nac_eu_west_2b.public_ip
    nac_eu_west_2c_ip_address = aws_eip.nac_eu_west_2c.public_ip
  }
}

output "ec2" {
  value = {
    radius_server_security_group_id   = aws_security_group.radius_server.id
    load_balancer_arn_suffix          = aws_lb.load_balancer.arn_suffix
    internal_load_balancer_arn_suffix = aws_lb.internal_load_balancer.arn_suffix
  }
}

output "cloudwatch" {
  value = {
    server_log_group_name       = aws_cloudwatch_log_group.server_log_group.name
    server_nginx_log_group_name = aws_cloudwatch_log_group.server_nginx_log_group.name
  }
}

output "iam" {
  value = {
    ecs_task_role_arn      = aws_iam_role.ecs_task_role.arn
    ecs_execution_role_arn = aws_iam_role.ecs_execution_role.arn
  }
}

output "s3" {
  value = {
    radius_certificate_bucket_arn     = aws_s3_bucket.certificate_bucket.arn
    radius_certificate_bucket_name    = aws_s3_bucket.certificate_bucket.id
    radius_config_bucket_arn          = aws_s3_bucket.config_bucket.arn
    radius_config_bucket_name         = aws_s3_bucket.config_bucket.id
    radius_config_bucket_key_arn      = aws_kms_key.config_bucket_key.arn
    radius_certificate_bucket_key_arn = aws_kms_key.certificate_bucket_key.arn
  }
}

output "security_group_ids" {
  value = {
    radius_server = aws_security_group.radius_server.id
  }
}
