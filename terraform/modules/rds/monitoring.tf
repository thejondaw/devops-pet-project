# ================== MONITORING ================== #
# Enhanced monitoring IAM role
resource "aws_iam_role" "rds_enhanced_monitoring" {
  name = "${var.environment}-rds-monitoring-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "monitoring.rds.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  managed_policy_arns = ["arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"]

  tags = merge(local.common_tags, {
    Name = "${var.environment}-rds-monitoring-role"
    Type = "database-monitoring"
  })
}

# CloudWatch alarms for database monitoring
resource "aws_cloudwatch_metric_alarm" "database_connections" {
  alarm_name          = "${var.environment}-aurora-high-connections"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "DatabaseConnections"
  namespace           = "AWS/RDS"
  period              = "300"
  statistic           = "Average"
  threshold           = "100"
  alarm_description   = "This metric monitors database connections"
  alarm_actions       = [] # Add SNS topic ARN here

  dimensions = {
    DBClusterIdentifier = aws_rds_cluster.aurora_postgresql.cluster_identifier
  }

  tags = merge(local.common_tags, {
    Name = "${var.environment}-aurora-connections-alarm"
    Type = "monitoring-alarm"
  })
}

resource "aws_cloudwatch_metric_alarm" "cpu_utilization" {
  alarm_name          = "${var.environment}-aurora-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This metric monitors database CPU utilization"
  alarm_actions       = [] # Add SNS topic ARN here

  dimensions = {
    DBClusterIdentifier = aws_rds_cluster.aurora_postgresql.cluster_identifier
  }

  tags = merge(local.common_tags, {
    Name = "${var.environment}-aurora-cpu-alarm"
    Type = "monitoring-alarm"
  })
}

resource "aws_cloudwatch_metric_alarm" "freeable_memory" {
  alarm_name          = "${var.environment}-aurora-low-memory"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "FreeableMemory"
  namespace           = "AWS/RDS"
  period              = "300"
  statistic           = "Average"
  threshold           = "200000000" # 200MB in bytes
  alarm_description   = "This metric monitors database free memory"
  alarm_actions       = [] # Add SNS topic ARN here

  dimensions = {
    DBClusterIdentifier = aws_rds_cluster.aurora_postgresql.cluster_identifier
  }

  tags = merge(local.common_tags, {
    Name = "${var.environment}-aurora-memory-alarm"
    Type = "monitoring-alarm"
  })
}
