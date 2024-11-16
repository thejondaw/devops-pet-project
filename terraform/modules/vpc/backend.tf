# ==================================================== #
# =========== S3 BUCKET FOR BACKEND OF VPC =========== #
# ==================================================== #

# S3 Bucket - Backend
terraform {
  backend "s3" {
    bucket  = "alexsuff"
    key     = "project/develop/vpc.tfstate"
    region  = "us-east-2"
    encrypt = true
  }
}

# ==================================================== #
