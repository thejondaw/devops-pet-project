# S3 Bucket - Backend
terraform {
  backend "s3" {
    bucket  = "alexsuff"
    key     = "project/develop/vpc.tfstate"
    region  = "us-east-2"
    encrypt = true
  }
}

# Provider - Terraform
terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.9.0"
    }
  }
}

# Provider - AWS
provider "aws" {
  region = var.region
}
