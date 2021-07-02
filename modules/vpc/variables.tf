variable cidr_block {
    type = string
}

variable "cidr_block_new_bits" {
    type = number
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

variable "ocsp_endpoint" {
  type = string
}
