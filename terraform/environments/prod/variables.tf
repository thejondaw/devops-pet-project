# ==================================================== #
# ================ VARIABLES OF ROOT ================= #
# ==================================================== #

# Variable - AWS Region
variable "region" {
  description = "AWS Region"
  type        = string
}

# Variable - Environment
variable "environment" {
  description = "Environment name (develop, stage, prod)"
  type        = string
}

# Variable - S3 Bucket
variable "backend_bucket" {
  description = "Name of the S3 bucket for terraform state"
  type        = string
}

# Variable - Network Configuration
variable "vpc_configuration" {
  description = "VPC and subnet configuration"
  type = object({
    cidr = string
    subnets = object({
      web = object({
        cidr_block = string
        az         = string
      })
      alb = object({
        cidr_block = string
        az         = string
      })
      api = object({
        cidr_block = string
        az         = string
      })
      db = object({
        cidr_block = string
        az         = string
      })
    })
  })
}

# Variable - Database Configuration
variable "db_configuration" {
  description = "RDS configuration"
  type = object({
    name     = string
    username = string
  })
  sensitive = true
}

# Variable - EKS Configuration
variable "eks_configuration" {
  description = "EKS cluster configuration"
  type = object({
    version        = string
    min_size       = number
    max_size       = number
    instance_types = list(string)
  })
}

# ==================================================== #
