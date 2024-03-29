terraform {
  required_version = "1.1.3"

  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version               = "~> 3.0"
      configuration_aliases = [aws.env]
    }
  }
}
