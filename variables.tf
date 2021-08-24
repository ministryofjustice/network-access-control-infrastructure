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

variable "hosted_zone_id" {
  type = string
}

variable "hosted_zone_domain" {
  type = string
}

variable "admin_db_backup_retention_period" {
  type    = string
  default = "30"
}

variable "local_development_domain_affix" {
  type    = string
  default = ""
}

variable "transit_gateway_id" {
  type = string
}

variable "transit_gateway_route_table_id" {
  type = string
}

variable "ocsp_endpoint_ip" {
  type = string
}

variable "ocsp_endpoint_port" {
  type = string
}

variable "byoip_pool_id" {
  type = string
}

variable "enable_nac_transit_gateway_attachment" {
  type    = bool
  default = false
}

variable "enable_hosted_zone" {
  type = bool
  default = false
}

variable "admin_read_replica_db_username" {
  type = string
}

variable "admin_read_replica_db_password" {
  type = string
}

variable "ocsp_override_cert_url" {
  type = string
}

variable "enable_ocsp" {
  type = string
}
