
variable "subnet_ids" {
  type = list(string)
}

variable "prefix" {
  type = string
}

variable "tags" {
  type = map(string)
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

variable "replication_source" {
  type = string
}

variable "db_size" {
  type = string
}
