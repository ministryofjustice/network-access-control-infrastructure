variable cidr_block {
    type = string 
}

variable "cidr_block_new_bits" {
    type = number 
    default = 8
}

variable "prefix" {
    type = string
}