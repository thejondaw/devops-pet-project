# ==================================================== #
# ==================== ROOT MAIN ===================== #
# ==================================================== #

# AWS Region
provider "aws" {
  region = var.region
}

# ================== CUSTOM MODULES ================== #

# BACKEND - Module
module "backend" {
  source = "../terraform/modules/backend"

  environment = var.environment
  region      = var.region
  bucket_name = var.backend_bucket
}

# VPC - Module
module "vpc" {
  source = "../terraform/modules/vpc"

  environment       = var.environment
  region            = var.region
  vpc_configuration = var.vpc_configuration

  depends_on = [module.backend]
}

# RDS - Module
module "rds" {
  source = "../terraform/modules/rds"

  environment      = var.environment
  db_configuration = var.db_configuration

  depends_on = [module.vpc]
}

# EKS - Module
module "eks" {
  source = "../terraform/modules/eks"

  environment           = var.environment
  cluster_configuration = var.eks_configuration

  depends_on = [module.vpc]
}

# TOOLS - Module
module "tools" {
  source = "../../modules/tools"

  region      = var.region
  environment = var.environment
  environment_configuration = {
    namespaces = ["develop", "stage", "prod"]
  }

  depends_on = [module.eks]
}

# ==================================================== #
