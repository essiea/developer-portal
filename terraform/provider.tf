terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

terraform {
  backend "s3" {
    bucket  = "developer-portal-tfstate-163895578832"
    key     = "terraform.tfstate"
    encrypt = true
    region  = "us-east-1"
  }
}

