variable "cidr_block" {
  type = string
}

variable "cidr_block_new_bits" {
  type    = number
  default = 3
}

variable "enable_nac_transit_gateway_attachment" {
  type = bool
}

variable "prefix" {
  type = string
}

variable "tags" {
  type = map(string)
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

variable "mojo_dns_ip_1" {
  type = string
}

variable "mojo_dns_ip_2" {
  type = string
}

variable "ocsp_atos_cidr_range_1" {
  type = string
}

variable "ocsp_atos_cidr_range_2" {
  type = string
}

variable "region" {
  type = string
}

variable "ssm_session_manager_endpoints" {
  type    = bool
  default = false
}

variable "ocsp_dep_ip" {
  type = string
}

variable "ocsp_prs_ip" {
  type = string
}

variable "ocsp_dhl_ip" {
  type = string
}
