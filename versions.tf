terraform {
  required_version = "1.9.4"

  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version               = "~> 4.0"
      configuration_aliases = [aws.env]
    }
  }
}
