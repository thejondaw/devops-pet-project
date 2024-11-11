# ==================================================== #
# ================== BACKEND MODULE ================== #
# ==================================================== #

# "S3 Bucket" - Terraform State:
data "aws_s3_bucket" "terraform_state" {
  bucket = var.backend_bucket_rv
}

# "DynamoDB Table" - State Locking:
data "aws_dynamodb_table" "terraform_locks" {
  name = "${var.backend_bucket_rv}-locks"
}

# ============== S3 Bucket Settings ================= #

# Enable "Versioning" for State Files:
resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = data.aws_s3_bucket.terraform_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Enable Server-Side "Encryption":
resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = data.aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Block "Public Access":
resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket = data.aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ==================================================== #
