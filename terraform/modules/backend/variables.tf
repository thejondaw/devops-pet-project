# ==================================================== #
# =============== VARIABLES OF BACKEND =============== #
# ==================================================== #

# Variable - AWS Region
variable "region" {
  description = "AWS Region for backend resources"
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

# Variable - S3 Bucket - Name
variable "backend_bucket" {
  description = "Name of the S3 bucket for terraform state"
  type        = string
}

# ==================================================== #
