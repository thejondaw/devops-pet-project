# Variable - AWS Region
variable "region" {
  description = "AWS Region"
  type        = string
}

# Variable - Environment - Name
variable "environment" {
  description = "Environment name (develop, stage, prod)"
  type        = string
  validation {
    condition     = contains(["develop", "stage", "prod"], var.environment)
    error_message = "Environment must be develop, stage, or prod."
  }
}

# ============ EKS CLUSTER CONFIGURATION ============= #

variable "eks_configuration" {
  description = "EKS cluster configuration"
  type = object({
    version        = string
    min_size       = number
    max_size       = number
    disk_size      = number
    instance_types = list(string)
  })
  validation {
    condition     = can(regex("^1\\.(2[3-8])$", var.eks_configuration.version))
    error_message = "Kubernetes version must be between 1.23 and 1.28."
  }
}
