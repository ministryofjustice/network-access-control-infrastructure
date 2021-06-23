variable "radius_db_username" {
   type = string
}

variable "radius_db_password" {
   type = string
}

variable "service_name" {
   type = string
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

variable "vpn_hosted_zone_domain" {
   type = string
}

