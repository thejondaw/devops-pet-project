# Backend setup (must be deployed first)
module "backend" {
  source  = "../../modules/backend/"
  version = "1.0.0"

  region         = var.region
  backend_bucket = var.backend_bucket
}

# Network layer
module "vpc" {
  source = "../../modules/vpc"

  environment       = var.environment
  region            = var.region
  vpc_configuration = var.vpc_configuration
  cost_center       = var.cost_center
  allowed_ips       = var.allowed_ips

  depends_on = [module.backend]
}

# Database layer
module "rds" {
  source = "../../modules/rds"

  region           = var.region
  environment      = var.environment
  db_configuration = var.db_configuration

  depends_on = [module.vpc]
}

# Container orchestration layer
module "eks" {
  source = "../../modules/eks"

  region            = var.region
  environment       = var.environment
  eks_configuration = var.eks_configuration
  allowed_ips       = var.allowed_ips

  depends_on = [module.vpc]
}

# Platform tools layer
module "tools" {
  source = "../../modules/tools"

  region      = var.region
  environment = var.environment

  depends_on = [module.eks]
}
