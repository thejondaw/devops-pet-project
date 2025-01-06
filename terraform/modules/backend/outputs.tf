# Output - S3 Bucket - Name
output "bucket_name" {
  description = "Name of the S3 bucket used for state storage"
  value       = data.aws_s3_bucket.terraform_state.id
}

# Output - S3 Bucket - ARN
output "bucket_arn" {
  description = "ARN of the S3 bucket used for state storage"
  value       = data.aws_s3_bucket.terraform_state.arn
}

# Output - DynamoDB Table - Name
output "dynamodb_table_name" {
  description = "Name of the DynamoDB table used for state locking"
  value       = data.aws_dynamodb_table.terraform_locks.name
}
