variable "secret_key_base" {
  type        = string
  description = "Rails secret key base variable used for the admin platform"
}

variable "vpc" {
  type = object({
    id              = string
    public_subnets  = list(string)
    private_subnets = list(string)
  })

  description = "Networking configuration"
}

variable "db" {
  type = object({
    apply_updates_immediately = bool
    backup_retention_period   = number
    delete_automated_backups  = bool
    deletion_protection       = bool
    password                  = string
    skip_final_snapshot       = bool
    username                  = string
  })
}

variable "sentry_dsn" {
  type = string
}

variable "prefix" {
  type = string
}

variable "short_prefix" {
  type = string
}

variable "region" {
  type = string
}

variable "tags" {
  type = map(string)
}

variable "radius_certificate_bucket_arn" {
  type = string
}

variable "radius_certificate_bucket_name" {
  type = string
}

variable "radius_config_bucket_name" {
  type = string
}

variable "radius_config_bucket_arn" {
  type = string
}

variable "radius_config_bucket_key_arn" {
  type = string
}

variable "radius_certificate_bucket_key_arn" {
  type = string
}

variable "hosted_zone_id" {
  type = string
}

variable "hosted_zone_domain" {
  type = string
}

variable "cloudwatch_link" {
  type = string
}

variable "grafana_dashboard_link" {
  type = string
}

variable "server_ips" {
  type = string
}

variable "cognito_user_pool_id" {
  type = string
}

variable "cognito_user_pool_domain" {
  type = string
}

variable "cognito_user_pool_client_id" {
  type = string
}

variable "cognito_user_pool_client_secret" {
  type = string
}

variable "radius_cluster_name" {
  type = string
}

variable "radius_cluster_id" {
  type = string
}

variable "radius_service_name" {
  type = string
}

variable "radius_internal_service_name" {
  type = string
}

variable "radius_service_arn" {
  type = string
}

variable "radius_internal_service_arn" {
  type = string
}

variable "local_development_domain_affix" {
  type = string
}

variable "run_restore_from_backup" {
  type = bool
}

variable "eap_private_key_password" {
  type = string
}

variable "radsec_private_key_password" {
  type = string
}

variable "shared_services_account_id" {
  type = string
}