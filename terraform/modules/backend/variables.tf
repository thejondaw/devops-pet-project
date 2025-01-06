# ==================================================== #
# =============== VARIABLES OF BACKEND =============== #
# ==================================================== #

# Variable - AWS Region
variable "region" {
  description = "AWS Region for backend resources"
  type        = string
}

# Variable - S3 Bucket - Name
variable "backend_bucket" {
  description = "Name of the S3 bucket for terraform state"
  type        = string
}

# ==================================================== #
