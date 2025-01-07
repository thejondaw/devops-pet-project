# Expose bucket name for reference
output "bucket_name" {
  description = "Name of the S3 bucket used for state storage"
  value       = data.aws_s3_bucket.terraform_state.id
}

# Expose bucket ARN for IAM policies
output "bucket_arn" {
  description = "ARN of the S3 bucket used for state storage"
  value       = data.aws_s3_bucket.terraform_state.arn
}

# Expose DynamoDB table name for locking
output "dynamodb_table_name" {
  description = "Name of the DynamoDB table used for state locking"
  value       = data.aws_dynamodb_table.terraform_locks.name
}
