variable "subnets" {
  type = list(string)
}
variable "vpc_id" {
  type = string
}

variable "prefix" {
  type = string
}

variable "load_balancer_ip_address" {
  type = string
}
