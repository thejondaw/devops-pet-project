# S3 Bucket - Backend
terraform {
  required_version = ">= 1.0.0"
  backend "s3" {
    bucket  = "alexsuff"
    key     = "project/develop/rds.tfstate"
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
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

# Provider - AWS
provider "aws" {
  region = var.region
}

# =================== DATA SOURCES =================== #

# Fetch - VPC
data "aws_vpc" "main" {
  filter {
    name   = "tag:Name"
    values = ["devops-pet-project-vpc"]
  }
}

# Fetch - Subnet API
data "aws_subnet" "api" {
  filter {
    name   = "tag:Name"
    values = ["subnet-api"]
  }
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.main.id]
  }
}

# Fetch - Subnet DB
data "aws_subnet" "db" {
  filter {
    name   = "tag:Name"
    values = ["subnet-db"]
  }
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.main.id]
  }
}
