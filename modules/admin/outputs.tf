output "admin_db_identifier" {
  value = aws_db_instance.admin_db.identifier
}

output "admin_url" {
  value = aws_route53_record.admin_app.fqdn
}

output "ecs" {
  value = {
    cluster_name                   = var.radius_cluster_name
    service_name                   = aws_ecs_service.admin_service.name
    background_worker_service_name = aws_ecs_service.admin_background_worker_service.name
    task_definition_name           = aws_ecs_task_definition.admin_task.id
  }
}

output "ecr" {
  value = {
    repository_url = aws_ecr_repository.admin_ecr.repository_url
  }
}

output "rds" {
  value = {
    admin_db_id         = aws_db_instance.admin_db.id
    admin_db_arn        = aws_db_instance.admin_db.arn
    rds_monitoring_role = aws_iam_role.rds_monitoring_role.arn
  }
}
