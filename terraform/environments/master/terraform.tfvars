# Set - AWS Region
region = "us-east-2"

# Set - S3 Bucket - Name
backend_bucket = "alexsuff"

# Set - Environment - Name
environment = "master"

# Set - VPC & Subnets - Configuration
vpc_configuration = {
  cidr = "10.0.0.0/16"
  subnets = {
    web = {
      cidr_block = "10.0.1.0/24"
      az         = "us-east-2a"
    }
    alb = {
      cidr_block = "10.0.2.0/24"
      az         = "us-east-2b"
    }
    api = {
      cidr_block = "10.0.3.0/24"
      az         = "us-east-2a"
    }
    db = {
      cidr_block = "10.0.4.0/24"
      az         = "us-east-2c"
    }
  }
}

# Set - Database - Configuration
db_configuration = {
  name     = "devopsdb"
  username = "jondaw"
  port     = 5432
}

# Set - EKS Cluster - Condfiguration
eks_configuration = {
  version        = "1.28"
  min_size       = 2
  max_size       = 3
  instance_types = ["t3.medium"]
  disk_size      = 20
}
