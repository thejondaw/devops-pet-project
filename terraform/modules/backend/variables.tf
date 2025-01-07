# AWS Region for resource deployment
variable "region" {
  description = "AWS Region for backend resources"
  type        = string
}

# S3 bucket name for terraform state
variable "backend_bucket" {
  description = "Name of the S3 bucket for terraform state"
  type        = string
}
