terraform {
  required_version = ">= 1.7.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.60"
    }
  }

  backend "s3" {
    bucket         = "wapa-tfstate-prod"
    key            = "envs/prod/terraform.tfstate"
    region         = "eu-west-3"
    dynamodb_table = "wapa-tfstate-lock"
    encrypt        = true
  }
}

provider "aws" {
  region = "eu-west-3"

  default_tags {
    tags = {
      Project     = "wapaexchange"
      Environment = "prod"
      ManagedBy   = "terraform"
    }
  }
}
