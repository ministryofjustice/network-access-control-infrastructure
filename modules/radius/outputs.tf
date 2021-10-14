output "ecr" {
  value = {
    repository_url       = aws_ecr_repository.docker_repository.repository_url
    registry_id          = aws_ecr_repository.docker_repository.registry_id
    nginx_repository_url = aws_ecr_repository.docker_repository_nginx.repository_url
  }
}

output "ecs" {
  value = {
    service_arn = aws_ecs_service.service.id
    service_name = aws_ecs_service.service.name
    cluster_name = aws_ecs_cluster.server_cluster.name
    internal_service_name = aws_ecs_service.internal_service.name
    internal_service_arn = aws_ecs_service.internal_service.id
  }
}

output "ec2" {
  value = {
    radius_server_security_group_id = aws_security_group.radius_server.id
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
    radius_certificate_bucket_arn  = aws_s3_bucket.certificate_bucket.arn
    radius_certificate_bucket_name = aws_s3_bucket.certificate_bucket.id
    radius_config_bucket_arn = aws_s3_bucket.config_bucket.arn
    radius_config_bucket_name = aws_s3_bucket.config_bucket.id
    radius_config_bucket_key_arn = aws_kms_key.config_bucket_key.arn
    radius_certificate_bucket_key_arn = aws_kms_key.certificate_bucket_key.arn
  }
}
