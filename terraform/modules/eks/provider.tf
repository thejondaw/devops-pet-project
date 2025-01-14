# S3 Bucket - Backend
terraform {
  backend "s3" {
    bucket  = "alexsuff"
    key     = "project/develop/eks.tfstate"
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

# =================== DATA SOURCES ================== #

# Fetch - VPC
data "aws_vpc" "main" {
  filter {
    name   = "tag:Name"
    values = ["devops-pet-project-vpc"]
  }
}

# Fetch - Subnet Web
data "aws_subnet" "web" {
  filter {
    name   = "tag:Name"
    values = ["subnet-web"]
  }
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.main.id]
  }
}

# Fetch - Subnet ALB
data "aws_subnet" "alb" {
  filter {
    name   = "tag:Name"
    values = ["subnet-alb"]
  }
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.main.id]
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

# Fetch - Current Region
data "aws_region" "current" {}

# Fetch Account ID
data "aws_caller_identity" "current" {}
