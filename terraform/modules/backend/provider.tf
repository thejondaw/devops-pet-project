# Provider - Terraform
terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  backend "s3" {
    bucket  = "alexsuff"
    key     = "project/backend.tfstate"
    region  = "us-east-2"
    encrypt = true
  }
}

# Provider configuration using variables
provider "aws" {
  region = var.region
}

# S3 Bucket - Terraform State
data "aws_s3_bucket" "terraform_state" {
  bucket = var.backend_bucket
}

# DynamoDB Table - State Locking
data "aws_dynamodb_table" "terraform_locks" {
  name = "${var.backend_bucket}-locks"
}
