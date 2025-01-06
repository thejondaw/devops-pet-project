# Variable - AWS Region
variable "region" {
  description = "AWS Region"
  type        = string
}

# Variable - Environment
variable "environment" {
  description = "Environment name (develop, stage, prod)"
  type        = string
  validation {
    condition     = contains(["develop", "stage", "prod"], var.environment)
    error_message = "Environment must be develop, stage, or prod."
  }
}

# ===================== NETWORK ====================== #

# Variable - CIDR Block - Subnets
variable "vpc_configuration" {
  description = "VPC configuration including CIDR and subnets"
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
    condition     = can(cidrhost(var.vpc_configuration.cidr, 0))
    error_message = "Must be a valid IPv4 CIDR block."
  }
}

# Variable - Allowed IPs
variable "allowed_ips" {
  description = "List of allowed IP ranges for web access"
  type        = list(string)
  default     = ["YOUR.OFFICE.IP/32", "YOUR.VPN.IP/32"]
}
