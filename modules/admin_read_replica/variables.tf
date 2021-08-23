
variable "subnet_ids" {
  type = list(string)
}

variable "prefix" {
  type = string
}

variable "tags" {
  type = map(string)
}

variable "db_username" {
  type = string
}

variable "db_password" {
  type = string
}

variable "rds_monitoring_role" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "admin_db_id" {
  type = string
}
