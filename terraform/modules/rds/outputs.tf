# Output - DB - Endpoint
output "db_endpoint" {
  description = "RDS cluster endpoint"
  value       = aws_rds_cluster.aurora_postgresql.endpoint
}

# Output - DB - Name
output "db_name" {
  description = "Database name"
  value       = aws_rds_cluster.aurora_postgresql.database_name
}

# Output - Secret Manager - Secret Name
output "secret_name" {
  description = "Name of the secret in AWS Secrets Manager"
  value       = aws_secretsmanager_secret.aurora_secret.name
}

output "database_password" {
  value     = random_password.aurora_password.result
  sensitive = true
}
