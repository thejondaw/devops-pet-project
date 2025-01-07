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

# Monitoring configuration
output "monitoring_interval" {
  description = "Enhanced Monitoring interval in seconds"
  value       = aws_rds_cluster_instance.rds_instance.monitoring_interval
}

output "performance_insights_enabled" {
  description = "Whether Performance Insights is enabled"
  value       = aws_rds_cluster_instance.rds_instance.performance_insights_enabled
}
