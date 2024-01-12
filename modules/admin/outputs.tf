output "admin_db_identifier" {
  value = aws_db_instance.admin_db.identifier
}

output "admin_url" {
  value = aws_route53_record.admin_app.fqdn
}

output "ecs" {
  value = {
    cluster_name                   = var.radius_cluster_name
    service_name                   = aws_ecs_service.admin.name
    background_worker_service_name = aws_ecs_service.admin_background_worker.name
    task_definition_name           = aws_ecs_task_definition.admin.id
  }
}

output "ecr" {
  value = {
    repository_url = aws_ecr_repository.admin.repository_url
  }
}

output "rds" {
  value = {
    admin_db_id         = var.run_restore_from_backup ? element(aws_db_instance.admin_db_restored.*.id, 0) : aws_db_instance.admin_db.id
    admin_db_arn        = var.run_restore_from_backup ? element(aws_db_instance.admin_db_restored.*.arn, 0) : aws_db_instance.admin_db.arn
    rds_monitoring_role = aws_iam_role.rds_monitoring_role.arn
    fqdn = aws_route53_record.admin_db.fqdn
    endpoint = aws_db_instance.admin_db.endpoint
    name = aws_db_instance.admin_db.name
    port = aws_db_instance.admin_db.port
    username = aws_db_instance.admin_db.username
  }
}

output "security_group_ids" {
  value = {
    admin_ecs = aws_security_group.admin_ecs.id
  }
}
