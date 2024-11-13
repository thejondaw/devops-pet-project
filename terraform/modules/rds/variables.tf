# ==================================================== #
# ============== VARIABLES OF RDS MODULE ============= #
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
  validation {
    condition     = contains(["develop", "stage", "prod"], var.environment)
    error_message = "Environment must be develop, stage, or prod."
  }
}

# ============== DATABASE CONFIGURATION ============== #

# Database Credentials
variable "db_configuration" {
  description = "Database configuration settings"
  type = object({
    name     = string
    username = string
    password = string
    port     = number
  })
  validation {
    condition     = var.db_configuration.port >= 1024 && var.db_configuration.port <= 65535
    error_message = "Database port must be between 1024 and 65535."
  }
}

# ==================================================== #
