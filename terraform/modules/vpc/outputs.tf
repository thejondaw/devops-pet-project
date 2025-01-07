# VPC Outputs
output "vpc_id" {
  description = "ID of the created VPC"
  value       = aws_vpc.main.id
}

output "vpc_cidr_block" {
  description = "CIDR block of the created VPC"
  value       = aws_vpc.main.cidr_block
}

# Subnet Outputs
output "subnet_ids" {
  description = "Map of created subnet IDs"
  value = {
    web = aws_subnet.subnet_web[*].id
    alb = aws_subnet.subnet_alb[*].id
    api = aws_subnet.subnet_api[*].id
    db  = aws_subnet.subnet_db[*].id
  }
}

# Security Group Output
output "security_group_id" {
  description = "ID of the main VPC security group"
  value       = aws_security_group.main_vpc_sg.id
}

# Network Configuration Output
output "network_configuration" {
  description = "Network configuration for other modules"
  value = {
    vpc_id = aws_vpc.main.id
    subnets = {
      web = [for subnet in aws_subnet.subnet_web : {
        id         = subnet.id
        cidr_block = subnet.cidr_block
      }]
      alb = [for subnet in aws_subnet.subnet_alb : {
        id         = subnet.id
        cidr_block = subnet.cidr_block
      }]
      api = [for subnet in aws_subnet.subnet_api : {
        id         = subnet.id
        cidr_block = subnet.cidr_block
      }]
    }
  }
}
