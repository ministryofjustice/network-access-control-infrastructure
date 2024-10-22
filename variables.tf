variable "service_name" {
  type    = string
  default = "nac"
}

variable "enable_authentication" {
  type    = bool
  default = true
}

variable "admin_db_backup_retention_period" {
  type    = string
  default = "30"
}

variable "local_development_domain_affix" {
  type    = string
  default = ""
}

variable "enable_nac_transit_gateway_attachment" {
  type    = bool
  default = true
}

variable "enable_hosted_zone" {
  type    = bool
  default = true
}

#TODO check the correct value for this email
variable "owner_email" {
  type    = string
  default = "lanwifi-devops@digital.justice.gov.uk"
}

variable "allowed_ips" {
  type        = list(string)
  description = "List of allowed IP addresses"
  default     = []
}
