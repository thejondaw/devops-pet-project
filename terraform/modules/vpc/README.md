## VPC Module

### Overview
Creates a secure multi-AZ VPC infrastructure with public and private subnets.

### Key Features
- Multi-AZ design for high availability
- Separate subnets for different tiers (web, alb, api, db)
- Flow logs enabled and encrypted with KMS
- VPC Endpoints for AWS services to reduce NAT costs
- Security groups with minimal required access
- NACL rules for additional security layer

### Resources Created
- VPC with IPv4 CIDR
- 2 Public subnets (web, alb)
- 2 Private subnets (api, db)
- Internet Gateway
- NAT Gateway
- Route tables
- Network ACLs
- Security Groups
- Flow Logs with CloudWatch integration
- VPC Endpoints (S3, DynamoDB)

### Design Decisions
- Public subnets for web/ALB tier due to internet-facing requirements
- Private subnets for API/DB for security
- NAT Gateway in web subnet for outbound internet access
- NACL rules configured to block common attack vectors
- Flow logs enabled for security auditing
