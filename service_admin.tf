module "admin" {
  source                            = "./modules/admin"
  prefix                            = "${module.label.id}-admin"
  short_prefix                      = module.label.stage # avoid 32 char limit on certain resources
  tags                              = module.label.tags
  run_restore_from_backup           = local.run_restore_from_backup
  sentry_dsn                        = var.admin_sentry_dsn
  secret_key_base                   = "tbc"
  radius_certificate_bucket_arn     = module.radius.s3.radius_certificate_bucket_arn
  radius_certificate_bucket_name    = module.radius.s3.radius_certificate_bucket_name
  radius_config_bucket_name         = module.radius.s3.radius_config_bucket_name
  radius_config_bucket_arn          = module.radius.s3.radius_config_bucket_arn
  radius_config_bucket_key_arn      = module.radius.s3.radius_config_bucket_key_arn
  radius_certificate_bucket_key_arn = module.radius.s3.radius_certificate_bucket_key_arn
  region                            = data.aws_region.current_region.id
  hosted_zone_id                    = var.hosted_zone_id
  hosted_zone_domain                = var.hosted_zone_domain
  radius_cluster_name               = module.radius.ecs.cluster_name
  radius_cluster_id                 = module.radius.ecs.cluster_id
  radius_service_name               = module.radius.ecs.service_name
  radius_internal_service_name      = module.radius.ecs.internal_service_name
  radius_service_arn                = module.radius.ecs.service_arn
  radius_internal_service_arn       = module.radius.ecs.internal_service_arn
  cognito_user_pool_id              = module.authentication.cognito_user_pool_id
  cognito_user_pool_domain          = module.authentication.cognito_user_pool_domain
  cognito_user_pool_client_id       = module.authentication.cognito_user_pool_client_id
  cognito_user_pool_client_secret   = module.authentication.cognito_user_pool_client_secret
  local_development_domain_affix    = var.local_development_domain_affix
  cloudwatch_link                   = var.cloudwatch_link
  grafana_dashboard_link            = var.grafana_dashboard_link
  eap_private_key_password          = var.eap_private_key_password
  radsec_private_key_password       = var.radsec_private_key_password
  shared_services_account_id        = var.shared_services_account_id
  server_ips = join(", ", [
    module.radius.load_balancer.nac_eu_west_2a_ip_address,
    module.radius.load_balancer.nac_eu_west_2b_ip_address,
    module.radius.load_balancer.nac_eu_west_2c_ip_address
  ])

  db = {
    apply_updates_immediately = local.is_production ? false : true
    backup_retention_period   = var.admin_db_backup_retention_period
    delete_automated_backups  = local.is_production ? false : true
    deletion_protection       = local.is_production ? true : false
    password                  = var.admin_db_password
    skip_final_snapshot       = true
    username                  = var.admin_db_username
  }

  vpc = {
    id              = module.admin_vpc.vpc_id
    public_subnets  = module.admin_vpc.public_subnets
    private_subnets = module.admin_vpc.private_subnets
  }

  depends_on = [
    module.admin_vpc
  ]

  providers = {
    aws = aws.env
  }
}
