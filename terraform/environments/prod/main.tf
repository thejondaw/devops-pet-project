# Set required Terraform version and providers
terraform {
  required_version = ">= 1.0.0, < 2.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}

# BACKEND Module
module "backend" {
  source  = "../../modules/backend/"
  version = "1.0.0"

  region         = var.region
  backend_bucket = var.backend_bucket
}

# VPC Module
module "vpc" {
  source = "../../modules/vpc"

  environment       = var.environment
  region            = var.region
  vpc_configuration = var.vpc_configuration

  depends_on = [module.backend]
}

# RDS Module
module "rds" {
  source = "../../modules/rds"

  region           = var.region
  environment      = var.environment
  db_configuration = var.db_configuration

  depends_on = [module.vpc]
}

# EKS Module
module "eks" {
  source = "../../modules/eks"

  region            = var.region
  environment       = var.environment
  eks_configuration = var.eks_configuration

  depends_on = [module.vpc]
}

# TOOLS Module
module "tools" {
  source = "../../modules/tools"

  region      = var.region
  environment = var.environment

  depends_on = [module.eks]
}
