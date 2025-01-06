# Fetch - VPC
data "aws_vpc" "main" {
  filter {
    name   = "tag:Name"
    values = ["devops-project-vpc"]
  }
}

# Fetch - Subnet API
data "aws_subnet" "api" {
  filter {
    name   = "tag:Name"
    values = ["subnet-api"]
  }
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.main.id]
  }
}

# Fetch - Subnet DB
data "aws_subnet" "db" {
  filter {
    name   = "tag:Name"
    values = ["subnet-db"]
  }
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.main.id]
  }
}

# ===================== DATABASE ===================== #

# Serverless v2 RDS cluster - Aurora PostgreSQL
resource "aws_rds_cluster" "aurora_postgresql" {
  cluster_identifier     = "${var.environment}-aurora-cluster"
  engine                 = "aurora-postgresql"
  engine_mode            = "provisioned"
  engine_version         = "15.3"
  database_name          = var.db_configuration.name
  master_username        = var.db_configuration.username
  master_password        = random_password.aurora_password.result
  port                   = var.db_configuration.port
  db_subnet_group_name   = aws_db_subnet_group.aurora_subnet_group.name
  vpc_security_group_ids = [aws_security_group.sg_aurora.id]
  skip_final_snapshot    = true

  # Encryption settings
  storage_encrypted = true
  kms_key_id        = aws_kms_key.rds.arn

  backup_retention_period = 14 # Keep backups for 14 days

  serverlessv2_scaling_configuration {
    max_capacity = 1.0
    min_capacity = 0.5
  }

  tags = {
    Name        = "${var.environment}-aurora-cluster"
    Environment = var.environment
    Project     = "devops-project"
    ManagedBy   = "terraform"
    Engine      = "aurora-postgresql"
  }
}

# Instance - RDS Cluster
resource "aws_rds_cluster_instance" "rds_instance" {
  cluster_identifier = aws_rds_cluster.aurora_postgresql.id
  instance_class     = "db.serverless"
  engine             = aws_rds_cluster.aurora_postgresql.engine
  engine_version     = aws_rds_cluster.aurora_postgresql.engine_version

  # Performance Insights with encryption
  performance_insights_enabled          = true
  performance_insights_kms_key_id       = aws_kms_key.rds.arn
  performance_insights_retention_period = 7 # Days

  # Enable enhanced monitoring
  monitoring_interval = 30
  monitoring_role_arn = aws_iam_role.rds_enhanced_monitoring.arn
}

# KMS key for RDS encryption
resource "aws_kms_key" "rds" {
  description             = "KMS key for RDS encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = {
    Name        = "${var.environment}-rds-encryption"
    Environment = var.environment
  }
}

# =================== SUBNET GROUP =================== #

# Subnet Group - RDS
resource "aws_db_subnet_group" "aurora_subnet_group" {
  name       = "aurora-subnet-group"
  subnet_ids = [data.aws_subnet.api.id, data.aws_subnet.db.id]

  tags = {
    Name        = "devops-project-aurora-subnet-group"
    Environment = var.environment
    Project     = "devops-project"
    ManagedBy   = "terraform"
  }
}

# ================= SECURITY GROUP =================== #

# Security Group - RDS Access
resource "aws_security_group" "sg_aurora" {
  name        = "aurora-db"
  description = "Allow Aurora PostgreSQL access"
  vpc_id      = data.aws_vpc.main.id

  # Incoming traffic for PostgreSQL only
  ingress {
    description = "Allow PostgreSQL traffic from VPC CIDR"
    from_port   = var.db_configuration.port
    to_port     = var.db_configuration.port
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.main.cidr_block]
  }

  # Outbound traffic to required AWS services only
  egress {
    description = "Allow outbound traffic to AWS services"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    prefix_list_ids = [
      "pl-6da54004", # AWS S3
      "pl-63a5400a"  # AWS DynamoDB
    ]
  }

  tags = {
    Name        = "devops-project-aurora-sg"
    Environment = var.environment
    Project     = "devops-project"
    ManagedBy   = "terraform"
    Type        = "database-security"
  }
}
