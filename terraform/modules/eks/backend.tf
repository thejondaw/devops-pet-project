# ==================================================== #
# =========== S3 Bucket for Backend of ECS =========== #
# ==================================================== #

# # "S3 Bucket" - Backend:
# terraform {
#   backend "s3" {
#     region = "us-east-2"
#     bucket = "alexsuff"
#     key    = "eks/terraform.tfstate"
#   }
# }

# ==================================================== #

# "S3 Bucket" - Backend:
terraform {
  backend "s3" {
    bucket         = "alexsuff"
    key            = "project/develop/eks.tfstate"
    region         = "us-east-2"
    dynamodb_table = "alexsuff-locks"
    encrypt        = true
  }
}

# ==================================================== #
