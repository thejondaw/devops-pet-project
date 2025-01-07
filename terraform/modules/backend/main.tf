# Enable versioning for state files to track changes
resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = data.aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Configure server-side encryption for state files
resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = data.aws_s3_bucket.terraform_state.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Block all public access for security
resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket = data.aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
