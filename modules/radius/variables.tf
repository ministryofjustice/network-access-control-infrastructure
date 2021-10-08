variable "prefix" {
  type = string
}

variable "short_prefix" {
  type = string
}

variable "vpc" {
  type = object({
    cidr = string
    id = string
    private_ip_eu_west_2a = string
    private_ip_eu_west_2b = string
    private_ip_eu_west_2c = string
    private_subnets = list(string)
    public_subnets = list(string)
  })
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

variable "hosted_zone_domain" {
  type = string
}

variable "enable_hosted_zone" {
  type = bool
  default = false
}

variable "tags" {
  type = map(string)
}

variable "local_development_domain_affix" {
  type = string
}

variable "read_replica" {
  type = object({
    name = string
    host = string
    user = string
    pass = string
  })
}

variable "enable_ocsp" {
  type = string
}

variable "ocsp_override_cert_url" {
  type = string
}

variable "read_replica_security_group_id" {
  type = string
}

variable "eap_private_key_password" {
  type = string
}

variable "radsec_private_key_password" {
  type = string
}

variable "mojo_dns_ip_1" {
  type = string
}

variable "mojo_dns_ip_2" {
  type = string
}

variable "hosted_zone_id" {
  type = string
}