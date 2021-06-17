variable "prefix" {
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

variable "log_filters" {
  type = list(string)
}