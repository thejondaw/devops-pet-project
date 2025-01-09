# Output - VPC ID
output "vpc_id" {
  description = "ID of the created VPC"
  value       = aws_vpc.main.id
}

# Output - Subnets IDs
output "subnet_ids" {
  description = "Map of created subnet IDs"
  value = {
    web = aws_subnet.subnet_web.id
    alb = aws_subnet.subnet_alb.id
    api = aws_subnet.subnet_api.id
    db  = aws_subnet.subnet_db.id
  }
}

# Output - CIDR Block
output "vpc_cidr_block" {
  description = "CIDR block of the created VPC"
  value       = aws_vpc.main.cidr_block
}

# Output - Security Groud ID
output "security_group_id" {
  description = "ID of the main VPC security group"
  value       = aws_security_group.sec_group_vpc.id
}

# Output - Network Configuration
output "network_configuration" {
  description = "Network configuration for other modules"
  value = {
    vpc_id = aws_vpc.main.id
    subnets = {
      web = {
        id         = aws_subnet.subnet_web.id
        cidr_block = aws_subnet.subnet_web.cidr_block
      }
      alb = {
        id         = aws_subnet.subnet_alb.id
        cidr_block = aws_subnet.subnet_alb.cidr_block
      }
      api = {
        id         = aws_subnet.subnet_api.id
        cidr_block = aws_subnet.subnet_api.cidr_block
      }
    }
  }
}
