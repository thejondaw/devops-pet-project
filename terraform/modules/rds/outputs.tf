# Output - DB - Endpoint
output "db_endpoint" {
  description = "Database endpoint"
  value       = aws_db_instance.postgresql.endpoint
}

# Output - DB - Name
output "db_name" {
  description = "Database name"
  value       = aws_db_instance.postgresql.db_name
}

# Output - DB Password
output "database_password" {
  value     = random_password.postgresql_password.result
  sensitive = true
}
