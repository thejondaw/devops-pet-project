# AWS Region configuration
variable "region" {
  description = "AWS Region for resource deployment"
  type        = string
}

# Environment name validation
variable "environment" {
  description = "Environment name (develop, stage, prod)"
  type        = string
  validation {
    condition     = contains(["develop", "stage", "prod"], var.environment)
    error_message = "Environment must be develop, stage, or prod."
  }
}

# Network configuration with multi-AZ support
variable "vpc_configuration" {
  description = "VPC network configuration including CIDR and multi-AZ subnets"
  type = object({
    cidr = string
    subnets = object({
      web = list(object({
        cidr_block = string
        az         = string
      }))
      alb = list(object({
        cidr_block = string
        az         = string
      }))
      api = list(object({
        cidr_block = string
        az         = string
      }))
      db = list(object({
        cidr_block = string
        az         = string
      }))
    })
  })
  validation {
    condition     = can(cidrhost(var.vpc_configuration.cidr, 0))
    error_message = "Must be a valid IPv4 CIDR block."
  }
}

# Security configuration
variable "allowed_ips" {
  description = "List of allowed IP ranges for web access"
  type        = list(string)
  default     = ["YOUR.OFFICE.IP/32", "YOUR.VPN.IP/32"]
}

# Cost tracking
variable "cost_center" {
  description = "Cost center tag for resource billing"
  type        = string
}
