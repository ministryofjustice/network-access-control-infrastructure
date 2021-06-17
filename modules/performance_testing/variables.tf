variable "subnets" {
  type = list(string)
}

variable "vpc_id" {
  type = string
}

variable "prefix" {
  type = string
  default = "moj-auth-poc"
}