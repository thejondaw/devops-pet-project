# VPC (Virtual Private Cloud)
resource "aws_vpc" "main" {
  cidr_block       = var.vpc_configuration.cidr
  instance_tenancy = "default"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "devops-project-vpc"
    Environment = var.environment
    Project     = "devops-project"
    ManagedBy   = "terraform"
  }
}

# ===================== SUBNETS ====================== #

# Public Subnet #1 - WEB
resource "aws_subnet" "subnet_web" {
  vpc_id     = aws_vpc.main.id
  cidr_block = var.vpc_configuration.subnets.web.cidr_block
  # We need auto-assign public IPs for EKS worker nodes to:
  # - Pull container images
  # - Access AWS services
  # - Connect to the internet for updates
  # In production consider:
  # - Using private subnets with NAT Gateway
  # - Implementing container image caching
  # - Setting up VPC endpoints for AWS services
  #tfsec:ignore:aws-ec2-no-public-ip-subnet
  map_public_ip_on_launch = true
  availability_zone       = var.vpc_configuration.subnets.web.az

  tags = {
    Name        = "subnet-web"
    Environment = var.environment
    Project     = "devops-project"
    ManagedBy   = "terraform"
    Type        = "public"
    Tier        = "web"
    # Adding required tags for EKS
    "kubernetes.io/role/elb"                    = "1"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }
}

# Consider adding these security controls:
resource "aws_network_acl" "web" {
  vpc_id     = aws_vpc.main.id
  subnet_ids = [aws_subnet.subnet_web.id]

  # Restrict inbound traffic
  ingress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 80
    to_port    = 80
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 110
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 443
    to_port    = 443
  }

  # Allow outbound traffic with ephemeral ports
  egress {
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  tags = {
    Name        = "web-nacl"
    Environment = var.environment
  }
}

# Public Subnet #2 - ALB
resource "aws_subnet" "subnet_alb" {
  vpc_id     = aws_vpc.main.id
  cidr_block = var.vpc_configuration.subnets.alb.cidr_block
  # Public IP required for ALB to:
  # - Accept inbound traffic from internet
  # - Route traffic to backend services
  # - Support SSL termination
  #tfsec:ignore:aws-ec2-no-public-ip-subnet
  map_public_ip_on_launch = true
  availability_zone       = var.vpc_configuration.subnets.alb.az

  tags = {
    Name        = "subnet-alb"
    Environment = var.environment
    Project     = "devops-project"
    ManagedBy   = "terraform"
    Type        = "public"
    Tier        = "alb"
    # Required tag for ALB auto-discovery
    "kubernetes.io/role/elb" = "1"
  }
}

# NACL for ALB subnet
resource "aws_network_acl" "alb" {
  vpc_id     = aws_vpc.main.id
  subnet_ids = [aws_subnet.subnet_alb.id]

  # Deny dangerous ports first
  ingress {
    protocol   = "tcp"
    rule_no    = 90
    action     = "deny"
    cidr_block = "0.0.0.0/0"
    from_port  = 3389 # RDP
    to_port    = 3389
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 91
    action     = "deny"
    cidr_block = "0.0.0.0/0"
    from_port  = 22 # SSH
    to_port    = 22
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 80
    to_port    = 80
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 110
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 443
    to_port    = 443
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 120
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 1024
    to_port    = 65535
  }

  egress {
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  tags = {
    Name        = "alb-nacl"
    Environment = var.environment
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
    Project     = "devops-project"
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
    Project     = "devops-project"
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
    Name        = "devops-project-igw"
    Environment = var.environment
    Project     = "devops-project"
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
    Name        = "devops-project-public-rt"
    Environment = var.environment
    Project     = "devops-project"
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
    Name        = "devops-project-nat"
    Environment = var.environment
    Project     = "devops-project"
    ManagedBy   = "terraform"
  }
}

# Route Table for Private Subnets
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name        = "devops-project-private-rt"
    Environment = var.environment
    Project     = "devops-project"
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

  # HTTP - restrict to known IPs or your office range instead of 0.0.0.0/0
  ingress {
    description = "HTTP from allowed IPs"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    #tfsec:ignore:aws-vpc-no-public-ingress-sgr
    cidr_blocks = var.allowed_ips
  }

  # HTTPS - same approach
  ingress {
    description = "HTTPS from allowed IPs"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    #tfsec:ignore:aws-vpc-no-public-ingress-sgr
    cidr_blocks = var.allowed_ips
  }

  # SSH - keep VPC-only
  ingress {
    description = "SSH from VPC only"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.vpc_configuration.cidr]
  }

  # Required outbound rules
  egress {
    description = "HTTPS outbound"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    #tfsec:ignore:aws-ec2-no-public-egress-sgr
    cidr_blocks = var.allowed_ips
  }

  egress {
    description = "HTTP outbound"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    #tfsec:ignore:aws-ec2-no-public-egress-sgr
    cidr_blocks = var.allowed_ips
  }

  egress {
    description = "DNS"
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    #tfsec:ignore:aws-ec2-no-public-egress-sgr
    cidr_blocks = var.allowed_ips
  }

  egress {
    description = "VPC internal"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_configuration.cidr]
  }

  tags = {
    Name        = "devops-project-vpc-sg"
    Environment = var.environment
    Project     = "devops-project"
    ManagedBy   = "terraform"
    Type        = "vpc-security"
  }
}
