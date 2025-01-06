# S3 Bucket - Backend
terraform {
  backend "s3" {
    bucket  = "alexsuff"
    key     = "project/develop/eks.tfstate"
    region  = "us-east-2"
    encrypt = true
  }
}
