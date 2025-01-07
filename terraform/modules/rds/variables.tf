# AWS deployment region
variable "region" {
  description = "AWS Region"
  type        = string
}

# Environment tag
variable "environment" {
  description = "Environment name (develop, stage, prod)"
  type        = string
  validation {
    condition     = contains(["develop", "stage", "prod"], var.environment)
    error_message = "Environment must be develop, stage, or prod."
  }
}

# Database configuration settings
variable "db_configuration" {
  description = "Aurora PostgreSQL configuration"
  type = object({
    name     = string # Database name
    username = string # Master username
    port     = number # Database port
  })
  validation {
    condition     = var.db_configuration.port >= 1024 && var.db_configuration.port <= 65535
    error_message = "Database port must be between 1024 and 65535."
  }
}

# Common tags for all resources
locals {
  common_tags = {
    Environment = var.environment
    Project     = "devops-project"
    ManagedBy   = "terraform"
    Service     = "aurora-postgresql"
    Owner       = "DevOps"
  }
}
