# ==================================================== #
# =========== S3 Bucket for Backend of RDS =========== #
# ==================================================== #

# "S3 Bucket" - Backend:
terraform {
  backend "s3" {
    region = "us-east-2"
    bucket = "alexsuff"
    key    = "toptal/RDS/terraform.tfstate"
  }
}

# ==================================================== #