# Parameter group for PostgreSQL logging
resource "aws_db_parameter_group" "postgresql" {
  family = "postgres17"
  name   = "${var.environment}-postgres-params"

  parameter {
    name  = "log_statement"
    value = "all"
  }

  parameter {
    name  = "log_min_duration_statement"
    value = "1000"
  }

  parameter {
    name  = "rds.force_ssl"
    value = "0"
  }
}

# Main PostgreSQL instance with cost-effective settings
resource "aws_db_instance" "postgresql" {
  identifier = "${var.environment}-postgres"

  # Engine configuration
  engine         = "postgres"
  engine_version = "17.2"
  instance_class = "db.t4g.micro"

  # Storage configuration
  allocated_storage     = 20
  storage_type          = "gp2"
  max_allocated_storage = 0

  # Database settings
  db_name  = var.db_configuration.name
  username = var.db_configuration.username
  password = "password"
  port     = var.db_configuration.port

  # Network configuration
  db_subnet_group_name   = aws_db_subnet_group.postgresql_subnet_group.name
  vpc_security_group_ids = [aws_security_group.sg_postgresql.id]
  publicly_accessible    = false
  multi_az               = false
  network_type           = "IPV4"

  # Backup settings
  backup_retention_period = 1
  backup_window           = "03:00-04:00"
  maintenance_window      = "Mon:04:00-Mon:05:00"

  # Additional features
  performance_insights_enabled = false
  monitoring_interval          = 0

  # Version management
  auto_minor_version_upgrade  = true
  allow_major_version_upgrade = false

  # Protection settings
  deletion_protection      = false
  skip_final_snapshot      = true
  delete_automated_backups = true

  # Parameters
  parameter_group_name = aws_db_parameter_group.postgresql.name

  tags = {
    Name        = "${var.environment}-postgres"
    Environment = var.environment
    Project     = "devops-pet-project"
    ManagedBy   = "terraform"
    Engine      = "postgresql"
  }
}

# =================== SUBNET GROUP =================== #

# Subnet Group for RDS networking
resource "aws_db_subnet_group" "postgresql_subnet_group" {
  name       = "postgres-subnet-group"
  subnet_ids = [data.aws_subnet.api.id, data.aws_subnet.db.id]

  tags = {
    Name        = "devops-pet-project-postgres-subnet-group"
    Environment = var.environment
    Project     = "devops-pet-project"
    ManagedBy   = "terraform"
  }
}

# ================= SECURITY GROUP =================== #

# Security Group for PostgreSQL access control
resource "aws_security_group" "sg_postgresql" {
  name        = "postgres-db"
  description = "Allow PostgreSQL access"
  vpc_id      = data.aws_vpc.main.id

  ingress {
    description = "Allow PostgreSQL traffic from VPC CIDR"
    from_port   = var.db_configuration.port
    to_port     = var.db_configuration.port
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.main.cidr_block]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "devops-pet-project-postgres-sg"
    Environment = var.environment
    Project     = "devops-pet-project"
    ManagedBy   = "terraform"
    Type        = "database-security"
  }
}
