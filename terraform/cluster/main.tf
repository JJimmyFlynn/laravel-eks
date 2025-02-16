terraform {
  backend "s3" {
    bucket         = "flynn-tfstate-php-infra-poc"
    key            = "laravel-k8s"
    region         = "us-east-1"
    dynamodb_table = "php-infra-state-lock"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.84.0"
    }

    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 5"
    }
  }
}

provider "aws" {
  region = var.region

  assume_role {
    role_arn = var.role_arn
  }
}
