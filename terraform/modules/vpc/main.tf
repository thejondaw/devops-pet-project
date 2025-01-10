# VPC (Virtual Private Cloud)
resource "aws_vpc" "main" {
  cidr_block       = var.vpc_configuration.cidr
  instance_tenancy = "default"

  tags = {
    Name        = "devops-pet-project-vpc"
    Environment = var.environment
    Project     = "devops-pet-project"
    ManagedBy   = "terraform"
  }
}

# ===================== SUBNETS ====================== #

# Public Subnet #1 - WEB
resource "aws_subnet" "subnet_web" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.vpc_configuration.subnets.web.cidr_block
  map_public_ip_on_launch = true
  availability_zone       = var.vpc_configuration.subnets.web.az

  tags = {
    Name        = "subnet-web"
    Environment = var.environment
    Project     = "devops-pet-project"
    ManagedBy   = "terraform"
    Type        = "public"
    Tier        = "web"
    # Adding required tags for EKS
    "kubernetes.io/role/elb"                    = "1"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }
}

# Public Subnet #2 - ALB
resource "aws_subnet" "subnet_alb" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.vpc_configuration.subnets.alb.cidr_block
  map_public_ip_on_launch = true
  availability_zone       = var.vpc_configuration.subnets.alb.az

  tags = {
    Name        = "subnet-alb"
    Environment = var.environment
    Project     = "devops-pet-project"
    ManagedBy   = "terraform"
    Type        = "public"
    Tier        = "alb"
    # Required tag for ALB auto-discovery
    "kubernetes.io/role/elb" = "1"
  }
}

# Private Subnet #3 - API
resource "aws_subnet" "subnet_api" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.vpc_configuration.subnets.api.cidr_block
  availability_zone = var.vpc_configuration.subnets.api.az

  tags = {
    Name        = "subnet-api"
    Environment = var.environment
    Project     = "devops-pet-project"
    ManagedBy   = "terraform"
    Type        = "private"
    Tier        = "api"
  }
}

# Private Subnet #4 - DB
resource "aws_subnet" "subnet_db" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.vpc_configuration.subnets.db.cidr_block
  availability_zone = var.vpc_configuration.subnets.db.az

  tags = {
    Name        = "subnet-db"
    Environment = var.environment
    Project     = "devops-pet-project"
    ManagedBy   = "terraform"
    Type        = "private"
    Tier        = "database"
  }
}

# ========== INTERNET GATEWAY & ROUTE TABLE ========== #

# IGW (Internet Gateway)
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name        = "devops-pet-project-igw"
    Environment = var.environment
    Project     = "devops-pet-project"
    ManagedBy   = "terraform"
  }
}

# Route Table - Attach IGW to Public Subnets
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name        = "devops-pet-project-public-rt"
    Environment = var.environment
    Project     = "devops-pet-project"
    ManagedBy   = "terraform"
    Type        = "public"
  }
}
# Association - Public Subnet #1 WEB - Route Table
resource "aws_route_table_association" "public_web" {
  subnet_id      = aws_subnet.subnet_web.id
  route_table_id = aws_route_table.public_rt.id
}

# Association - Public Subnet #2 ALB - Route Table
resource "aws_route_table_association" "public_alb" {
  subnet_id      = aws_subnet.subnet_alb.id
  route_table_id = aws_route_table.public_rt.id
}

# ============ NAT GATEWAY & ROUTE TABLE ============= #

# Elastic IP for NAT Gateway
resource "aws_eip" "project-eip" {
  domain = "vpc"
}

# NAT Gateway
resource "aws_nat_gateway" "ngw" {
  allocation_id = aws_eip.project-eip.id
  subnet_id     = aws_subnet.subnet_web.id

  tags = {
    Name        = "devops-pet-project-nat"
    Environment = var.environment
    Project     = "devops-pet-project"
    ManagedBy   = "terraform"
  }
}

# Route Table for Private Subnets
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name        = "devops-pet-project-private-rt"
    Environment = var.environment
    Project     = "devops-pet-project"
    ManagedBy   = "terraform"
    Type        = "private"
  }
}

# Private Route - Private Subnets to NAT Gateway
resource "aws_route" "private_route" {
  route_table_id         = aws_route_table.private_rt.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.ngw.id
}

# Association - Private Subnet #3 API - Route Table
resource "aws_route_table_association" "Private_1" {
  subnet_id      = aws_subnet.subnet_api.id
  route_table_id = aws_route_table.private_rt.id
}

# Association - Private Subnet #4 DB - Route Table
resource "aws_route_table_association" "Private_2" {
  subnet_id      = aws_subnet.subnet_db.id
  route_table_id = aws_route_table.private_rt.id
}

# ================== SECURITY GROUP ================== #

# Main Security Group for VPC traffic
resource "aws_security_group" "sec_group_vpc" {
  name        = "sec-group-vpc"
  description = "Security group for VPC web and internal access"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP from allowed IPs"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS from allowed IPs"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH from VPC only"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.vpc_configuration.cidr]
  }

  ingress {
    description = "ArgoCD Web UI"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "devops-pet-project-vpc-sg"
    Environment = var.environment
    Project     = "devops-pet-project"
    ManagedBy   = "terraform"
    Type        = "vpc-security"
  }
}
