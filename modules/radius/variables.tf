variable "prefix" {
  type = string
}

variable "short_prefix" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "public_subnets" {
  type = list(string)
}

variable "private_subnets" {
  type = list(string)
}

variable "vpc_cidr" {
  type = string
}

variable "radius_db_username" {
  type = string
}

variable "radius_db_password" {
  type = string
}

variable "private_ip_eu_west_2a" {
  type = string
}

variable "private_ip_eu_west_2b" {
  type = string
}

variable "private_ip_eu_west_2c" {
  type = string
}

variable "log_filters" {
  type = list(string)
}

variable "env" {
  type = string
}

variable "byoip_pool_id" {
  type = string
}

variable "enable_nlb_deletion_protection" {
  type = bool
}

variable "ocsp_endpoint_ip" {
  type = string
}

variable "ocsp_endpoint_port" {
  type = string
}

variable "enable_hosted_zone" {
  type = bool
  default = false
}

variable "tags" {
  type = map(string)
}
