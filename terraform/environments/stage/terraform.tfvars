# AWS deployment region
region = "us-east-2"

# Backend state bucket
backend_bucket = "alexsuff"

# Environment name
environment = "stage"

# Cost tracking
cost_center = "devops-infrastructure"

# Access control
allowed_ips = [
  "10.0.0.0/8", # Internal network
  "YOUR.IP/32"  # Your specific IP
]

# Network configuration
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

# Database settings
db_configuration = {
  name     = "devopsdb"
  username = "jondaw"
  port     = 5432
}

# Kubernetes configuration
eks_configuration = {
  version        = "1.28"
  min_size       = 3
  max_size       = 3
  instance_types = ["t3.medium"]
  disk_size      = 20
}
