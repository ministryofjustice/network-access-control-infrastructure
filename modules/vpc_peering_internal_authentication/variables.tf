variable "target_aws_account_id" {
    type = string
}

variable "target_vpc_id" {
    type = string
}

variable "source_vpc_id" {
    type = string
}

variable "source_route_table_ids" {
  type = list(string)
}

variable "destination_route_table_ids" {
  type = list(string)
}

variable "destination_cidr" {
  type = string
}