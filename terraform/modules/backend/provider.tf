# Configure Terraform and providers
terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  # S3 backend configuration
  backend "s3" {
    bucket  = "alexsuff"
    key     = "project/backend.tfstate"
    region  = "us-east-2"
    encrypt = true
  }
}

# AWS Provider configuration
provider "aws" {
  region = var.region
}

# Use existing S3 bucket for state storage
data "aws_s3_bucket" "terraform_state" {
  bucket = var.backend_bucket
}

# Use existing DynamoDB table for state locking
data "aws_dynamodb_table" "terraform_locks" {
  name = "${var.backend_bucket}-locks"
}
