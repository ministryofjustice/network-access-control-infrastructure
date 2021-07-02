variable "radius_db_username" {
  type = string
}

variable "radius_db_password" {
  type = string
}

variable "service_name" {
  type    = string
  default = "nac"
}

variable "assume_role" {
  type = string
}

variable "azure_federation_metadata_url" {
  type = string
}

variable "enable_authentication" {
  type = bool
}

variable "admin_db_password" {
  type = string
}

variable "admin_db_username" {
  type = string
}

variable "admin_sentry_dsn" {
  type = string
}

variable "vpn_hosted_zone_id" {
  type = string
}

variable "vpn_hosted_zone_domain" {
  type = string
}

variable "admin_db_backup_retention_period" {
  type    = string
  default = "30"
}

variable "admin_local_development_domain_affix" {
  type = string
  default = ""
}

variable "transit_gateway_id" {
    type = string
}

variable "transit_gateway_route_table_id" {
    type = string
}

variable "ocsp_endpoint" {
  type = string
}
