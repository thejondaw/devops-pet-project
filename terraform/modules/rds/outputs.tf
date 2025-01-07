# Database endpoint for applications
output "db_endpoint" {
  description = "RDS cluster endpoint"
  value       = aws_rds_cluster.aurora_postgresql.endpoint
}

# Database name
output "db_name" {
  description = "Database name"
  value       = aws_rds_cluster.aurora_postgresql.database_name
}

# Secrets Manager secret name for credential management
output "secret_name" {
  description = "Name of the secret in AWS Secrets Manager"
  value       = aws_secretsmanager_secret.aurora_secret.name
}

# Database connection details
output "db_endpoint" {
  description = "RDS cluster endpoint for applications"
  value       = aws_rds_cluster.aurora_postgresql.endpoint
}

output "db_reader_endpoint" {
  description = "RDS cluster reader endpoint for read-only connections"
  value       = aws_rds_cluster.aurora_postgresql.reader_endpoint
}

output "db_port" {
  description = "Database port number"
  value       = aws_rds_cluster.aurora_postgresql.port
}

output "db_name" {
  description = "Database name"
  value       = aws_rds_cluster.aurora_postgresql.database_name
}

# Security and IAM outputs
output "secret_name" {
  description = "Name of the secret in AWS Secrets Manager"
  value       = aws_secretsmanager_secret.aurora_secret.name
}

output "secret_arn" {
  description = "ARN of the secret in AWS Secrets Manager"
  value       = aws_secretsmanager_secret.aurora_secret.arn
}

output "rds_monitoring_role_arn" {
  description = "ARN of the RDS monitoring IAM role"
  value       = aws_iam_role.rds_enhanced_monitoring.arn
}

# Network configuration
output "security_group_id" {
  description = "ID of the RDS security group"
  value       = aws_security_group.sg_aurora.id
}

output "subnet_group_name" {
  description = "Name of the RDS subnet group"
  value       = aws_db_subnet_group.aurora_subnet_group.name
}

# Monitoring configuration
output "monitoring_interval" {
  description = "Enhanced Monitoring interval in seconds"
  value       = aws_rds_cluster_instance.rds_instance.monitoring_interval
}

output "performance_insights_enabled" {
  description = "Whether Performance Insights is enabled"
  value       = aws_rds_cluster_instance.rds_instance.performance_insights_enabled
}

# Storage and backups
output "backup_retention_period" {
  description = "Number of days backups are retained"
  value       = aws_rds_cluster.aurora_postgresql.backup_retention_period
}

output "kms_key_id" {
  description = "ID of KMS key used for encryption"
  value       = aws_kms_key.rds.id
}
