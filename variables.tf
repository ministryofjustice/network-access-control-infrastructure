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

#variable "admin_sentry_dsn" {
#  type = string
#}

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
  type    = bool
  default = false
}

variable "ocsp_override_cert_url" {
  type = string
}

variable "enable_ocsp" {
  type = string
}

#variable "eap_private_key_password" {
#  type = string
#}

#variable "radsec_private_key_password" {
#  type = string
#}

variable "mojo_dns_ip_1" {
  type = string
}

variable "mojo_dns_ip_2" {
  type = string
}

variable "ocsp_atos_domain" {
  type = string
}

variable "radius_enable_packet_capture" {
  type = string
}

variable "packet_capture_duration_seconds" {
  type = string
}

variable "ocsp_atos_cidr_range_1" {
  type = string
}

variable "ocsp_atos_cidr_range_2" {
  type = string
}

variable "shared_services_account_id" {
  type = string
}

#TODO check the correct value for this email
variable "owner_email" {
  type    = string
  default = "nac@digital.justice.gov.uk"
}

variable "enable_rds_admin_bastion" {
  type    = bool
  default = false
}

variable "enable_rds_servers_bastion" {
  type    = bool
  default = false
}

variable "ocsp_dep_ip" {
  type = string
}

variable "allowed_ips" {
  type        = list(string)
  description = "List of allowed IP addresses"
  default     = []
}

variable "ocsp_prs_ip" {
  type = string
}

variable "ocsp_dhl_ip" {
  type = string
}
