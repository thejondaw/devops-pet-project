# S3 Bucket - Backend
terraform {
  required_version = ">= 1.0.0"
  backend "s3" {
    bucket  = "alexsuff"
    key     = "project/develop/eks.tfstate"
    region  = "us-east-2"
    encrypt = true
  }
}
