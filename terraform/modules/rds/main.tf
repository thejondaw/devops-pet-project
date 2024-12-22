# ==================================================== #
# ==================== RDS MODULE ==================== #
# ==================================================== #

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
  storage_encrypted      = true
  db_subnet_group_name   = aws_db_subnet_group.aurora_subnet_group.name
  vpc_security_group_ids = [aws_security_group.sg_aurora.id]
  skip_final_snapshot    = true

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

  # Default of PostgreSQL
  ingress {
    from_port   = var.db_configuration.port
    to_port     = var.db_configuration.port
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.main.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "devops-project-aurora-sg"
    Environment = var.environment
    Project     = "devops-project"
    ManagedBy   = "terraform"
    Type        = "database-security"
  }
}

# ==================================================== #
