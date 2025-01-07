# VPC Creation
resource "aws_vpc" "main" {
  cidr_block       = var.vpc_configuration.cidr
  instance_tenancy = "default"

  tags = merge(local.common_tags, {
    Name = "devops-project-vpc"
  })
}

# Public Subnets - Web Tier (Multi-AZ)
resource "aws_subnet" "subnet_web" {
  count = length(var.vpc_configuration.subnets.web)

  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.vpc_configuration.subnets.web[count.index].cidr_block
  availability_zone       = var.vpc_configuration.subnets.web[count.index].az
  #tfsec:ignore:aws-ec2-no-public-ip-subnet
  map_public_ip_on_launch = true

  tags = merge(local.common_tags, {
    Name                     = "subnet-web-${count.index + 1}"
    Type                     = "public"
    Tier                     = "web"
    "kubernetes.io/role/elb" = "1"
  })
}

# Public Subnets - ALB Tier (Multi-AZ)
resource "aws_subnet" "subnet_alb" {
  count = length(var.vpc_configuration.subnets.alb)

  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.vpc_configuration.subnets.alb[count.index].cidr_block
  availability_zone       = var.vpc_configuration.subnets.alb[count.index].az
  #tfsec:ignore:aws-ec2-no-public-ip-subnet
  map_public_ip_on_launch = true

  tags = merge(local.common_tags, {
    Name                     = "subnet-alb-${count.index + 1}"
    Type                     = "public"
    Tier                     = "alb"
    "kubernetes.io/role/elb" = "1"
  })
}

# Private Subnets - API Tier (Multi-AZ)
resource "aws_subnet" "subnet_api" {
  count = length(var.vpc_configuration.subnets.api)

  vpc_id            = aws_vpc.main.id
  cidr_block        = var.vpc_configuration.subnets.api[count.index].cidr_block
  availability_zone = var.vpc_configuration.subnets.api[count.index].az

  tags = merge(local.common_tags, {
    Name = "subnet-api-${count.index + 1}"
    Type = "private"
    Tier = "api"
  })
}

# Private Subnets - DB Tier (Multi-AZ)
resource "aws_subnet" "subnet_db" {
  count = length(var.vpc_configuration.subnets.db)

  vpc_id            = aws_vpc.main.id
  cidr_block        = var.vpc_configuration.subnets.db[count.index].cidr_block
  availability_zone = var.vpc_configuration.subnets.db[count.index].az

  tags = merge(local.common_tags, {
    Name = "subnet-db-${count.index + 1}"
    Type = "private"
    Tier = "database"
  })
}

# Internet Gateway for public access
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = merge(local.common_tags, {
    Name = "devops-project-igw"
  })
}

# NAT Gateways for private subnet internet access
resource "aws_nat_gateway" "ngw" {
  count = length(var.vpc_configuration.subnets.web)

  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.subnet_web[count.index].id

  tags = merge(local.common_tags, {
    Name = "devops-project-nat-${count.index + 1}"
  })
}

# Elastic IPs for NAT Gateways
resource "aws_eip" "nat" {
  count  = length(var.vpc_configuration.subnets.web)
  domain = "vpc"

  tags = merge(local.common_tags, {
    Name = "devops-project-eip-${count.index + 1}"
  })
}

# VPC Endpoints for AWS Services
resource "aws_vpc_endpoint" "s3" {
  vpc_id       = aws_vpc.main.id
  service_name = "com.amazonaws.${var.region}.s3"

  tags = merge(local.common_tags, {
    Name = "s3-endpoint"
  })
}

resource "aws_vpc_endpoint" "dynamodb" {
  vpc_id       = aws_vpc.main.id
  service_name = "com.amazonaws.${var.region}.dynamodb"

  tags = merge(local.common_tags, {
    Name = "dynamodb-endpoint"
  })
}

# Common tags for all resources
locals {
  common_tags = {
    Environment = var.environment
    Project     = "devops-project"
    ManagedBy   = "terraform"
    CostCenter  = var.cost_center
  }
}
