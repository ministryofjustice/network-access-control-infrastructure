terraform {
  required_version = "1.1.3"

  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version               = "5.75.1"
      configuration_aliases = [aws.env]
    }
  }
}
