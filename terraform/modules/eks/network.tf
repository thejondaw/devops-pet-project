# Get existing VPC
data "aws_vpc" "main" {
  filter {
    name   = "tag:Name"
    values = ["devops-project-vpc"]
  }
}

# Get existing web subnet
data "aws_subnet" "web" {
  filter {
    name   = "tag:Name"
    values = ["subnet-web"]
  }
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.main.id]
  }
}

# Get existing ALB subnet
data "aws_subnet" "alb" {
  filter {
    name   = "tag:Name"
    values = ["subnet-alb"]
  }
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.main.id]
  }
}

# Get existing API subnet
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
