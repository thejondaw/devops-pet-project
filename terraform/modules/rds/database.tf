# Generate secure master password
resource "random_password" "aurora_password" {
  length           = 16
  special          = true
  override_special = "!#$%^&*()-_=+[]{}<>:?"
}

# Store credentials in Secrets Manager
resource "aws_secretsmanager_secret" "aurora_secret" {
  name        = "${var.environment}/aurora/credentials"
  description = "Aurora PostgreSQL credentials"
  kms_key_id  = aws_kms_key.rds.arn

  tags = merge(local.common_tags, {
    Name = "${var.environment}-aurora-secret"
    Type = "database-secret"
  })
}

resource "aws_secretsmanager_secret_version" "aurora_secret_version" {
  secret_id = aws_secretsmanager_secret.aurora_secret.id
  secret_string = jsonencode({
    username = var.db_configuration.username
    password = random_password.aurora_password.result
    engine   = "aurora-postgresql"
    port     = var.db_configuration.port
    dbname   = var.db_configuration.name
    host     = aws_rds_cluster.aurora_postgresql.endpoint
  })
}

# RDS parameter group for PostgreSQL optimization
resource "aws_rds_cluster_parameter_group" "aurora_postgresql" {
  family = "aurora-postgresql15"
  name   = "${var.environment}-aurora-params"

  parameter {
    name  = "log_statement"
    value = "all"
  }

  parameter {
    name  = "log_min_duration_statement"
    value = "1000"
  }

  tags = merge(local.common_tags, {
    Name = "${var.environment}-aurora-params"
    Type = "database-config"
  })
}

# Main Aurora PostgreSQL cluster
resource "aws_rds_cluster" "aurora_postgresql" {
  cluster_identifier              = "${var.environment}-aurora-cluster"
  engine                          = "aurora-postgresql"
  engine_mode                     = "provisioned"
  engine_version                  = "15.3"
  database_name                   = var.db_configuration.name
  master_username                 = var.db_configuration.username
  master_password                 = random_password.aurora_password.result
  port                            = var.db_configuration.port
  db_subnet_group_name            = aws_db_subnet_group.aurora_subnet_group.name
  vpc_security_group_ids          = [aws_security_group.sg_aurora.id]
  skip_final_snapshot             = true
  db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.aurora_postgresql.name
  storage_encrypted               = true
  kms_key_id                      = aws_kms_key.rds.arn
  backup_retention_period         = 14

  # Serverless v2 configuration
  serverlessv2_scaling_configuration {
    max_capacity = 1.0
    min_capacity = 0.5
  }

  tags = merge(local.common_tags, {
    Name = "${var.environment}-aurora-cluster"
    Type = "database"
  })
}

# Aurora instance with monitoring
resource "aws_rds_cluster_instance" "rds_instance" {
  cluster_identifier = aws_rds_cluster.aurora_postgresql.id
  instance_class     = "db.serverless"
  engine             = aws_rds_cluster.aurora_postgresql.engine
  engine_version     = aws_rds_cluster.aurora_postgresql.engine_version

  # Performance Insights
  performance_insights_enabled          = true
  performance_insights_kms_key_id       = aws_kms_key.rds.arn
  performance_insights_retention_period = 7

  # Enhanced monitoring
  monitoring_interval = 30
  monitoring_role_arn = aws_iam_role.rds_enhanced_monitoring.arn

  tags = merge(local.common_tags, {
    Name = "${var.environment}-aurora-instance"
    Type = "database-instance"
  })
}

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
