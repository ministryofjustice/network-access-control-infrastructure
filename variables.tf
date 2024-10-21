variable "service_name" {
  type    = string
  default = "nac"
}

variable "assume_role" {
  type = string
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

# variable "shared_services_account_id" {
#   type = string
# }

#TODO check the correct value for this email
variable "owner_email" {
  type    = string
  default = "nac@digital.justice.gov.uk"
}

variable "allowed_ips" {
  type        = list(string)
  description = "List of allowed IP addresses"
  default     = []
}

# variable "ocsp_prs_ip" {
#   type = string
# }

# variable "ocsp_dhl_ip" {
#   type = string
# }
