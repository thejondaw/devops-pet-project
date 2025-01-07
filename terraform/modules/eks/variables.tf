# AWS deployment region
variable "region" {
  description = "AWS Region"
  type        = string
}

# Environment for resource tagging and naming
variable "environment" {
  description = "Environment name (develop, stage, prod)"
  type        = string
  validation {
    condition     = contains(["develop", "stage", "prod"], var.environment)
    error_message = "Environment must be develop, stage, or prod."
  }
}

# EKS cluster specifications
variable "eks_configuration" {
  description = "EKS cluster configuration"
  type = object({
    version        = string       # Kubernetes version
    min_size       = number       # Minimum node count
    max_size       = number       # Maximum node count
    disk_size      = number       # Node disk size in GB
    instance_types = list(string) # List of instance types for nodes
  })
  validation {
    condition     = can(regex("^1\\.(2[3-8])$", var.eks_configuration.version))
    error_message = "Kubernetes version must be between 1.23 and 1.28."
  }
}

# List of allowed CIDR blocks for EKS API access
variable "allowed_ips" {
  description = "List of CIDR blocks allowed to access EKS API endpoint"
  type        = list(string)
  validation {
    condition     = length(var.allowed_ips) > 0
    error_message = "At least one CIDR block must be specified for security"
  }
}
