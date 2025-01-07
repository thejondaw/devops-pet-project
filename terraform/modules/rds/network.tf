# Get existing VPC data
data "aws_vpc" "main" {
  filter {
    name   = "tag:Name"
    values = ["devops-project-vpc"]
  }
}

# Get API subnet for application layer
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

# Get DB subnet for database layer
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

# RDS subnet group for multi-AZ deployment
resource "aws_db_subnet_group" "aurora_subnet_group" {
  name       = "${var.environment}-aurora-subnet-group"
  subnet_ids = [data.aws_subnet.api.id, data.aws_subnet.db.id]

  tags = merge(local.common_tags, {
    Name = "${var.environment}-aurora-subnet-group"
    Type = "database-network"
  })
}

# Security group for RDS access
resource "aws_security_group" "sg_aurora" {
  name        = "${var.environment}-aurora-sg"
  description = "Security group for Aurora PostgreSQL access"
  vpc_id      = data.aws_vpc.main.id

  # Allow PostgreSQL access from VPC only
  ingress {
    description = "PostgreSQL from VPC"
    from_port   = var.db_configuration.port
    to_port     = var.db_configuration.port
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.main.cidr_block]
  }

  # Allow only necessary outbound traffic
  egress {
    description = "HTTPS to AWS services"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    prefix_list_ids = [
      "pl-6da54004", # S3
      "pl-63a5400a"  # DynamoDB
    ]
  }

  tags = merge(local.common_tags, {
    Name = "${var.environment}-aurora-sg"
    Type = "database-security"
  })
}
