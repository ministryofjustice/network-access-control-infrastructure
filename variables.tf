variable "target_aws_account_id" {
   type = string
}

variable "radius_db_username" {
   type = string
}

variable "radius_db_password" {
   type = string
}

variable "service_name" {
   type = string
   default = "nac"
}

variable "assume_role" {
   type = string
}
