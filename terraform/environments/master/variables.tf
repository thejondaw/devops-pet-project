# AWS Region configuration
variable "region" {
  description = "AWS deployment region"
  type        = string
}

# Environment name
variable "environment" {
  description = "Environment name (dev, stage, prod)"
  type        = string
  validation {
    condition     = contains(["dev", "stage", "prod"], var.environment)
    error_message = "Environment must be dev, stage, or prod."
  }
}

# Backend configuration
variable "backend_bucket" {
  description = "Name of the S3 bucket for terraform state"
  type        = string
}

# Network configuration
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
  validation {
    condition     = can(regex("^([0-9]{1,3}\\.){3}[0-9]{1,3}/[0-9]{1,2}$", var.vpc_configuration.cidr))
    error_message = "VPC CIDR block must be a valid IPv4 CIDR."
  }
}

# Database settings
variable "db_configuration" {
  description = "RDS configuration"
  type = object({
    name     = string
    username = string
    port     = number
  })
  sensitive = true
  validation {
    condition     = var.db_configuration.port >= 1024 && var.db_configuration.port <= 65535
    error_message = "Database port must be between 1024 and 65535."
  }
}

# EKS configuration
variable "eks_configuration" {
  description = "EKS cluster configuration"
  type = object({
    version        = string
    min_size       = number
    max_size       = number
    instance_types = list(string)
    disk_size      = number
  })
  validation {
    condition     = can(regex("^1\\.(2[3-9]|30)$", var.eks_configuration.version))
    error_message = "Kubernetes version must be between 1.23 and 1.30."
  }
}

# Cost center for billing
variable "cost_center" {
  description = "Cost center tag for resource billing"
  type        = string
}

# Allowed IP ranges
variable "allowed_ips" {
  description = "List of allowed IP ranges for service access"
  type        = list(string)
  validation {
    condition     = length(var.allowed_ips) > 0
    error_message = "At least one IP range must be specified."
  }
}
