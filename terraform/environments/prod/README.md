# Infrastructure Root Module

## Overview
The root module orchestrates the deployment of a complete AWS infrastructure stack including VPC, RDS, EKS, and operational tools.

### Key Features
- Complete infrastructure deployment with one command
- Environment-based configuration
- Module dependencies management
- Secure variable handling
- Multi-AZ infrastructure

### Modules Used
1. **Backend Module**
   - S3 state storage
   - State locking with DynamoDB

2. **VPC Module**
   - Multi-AZ networking
   - Public/private subnets
   - Security groups and NACLs

3. **RDS Module**
   - Aurora PostgreSQL serverless
   - Encrypted storage
   - Automated backups

4. **EKS Module**
   - Managed Kubernetes
   - Spot instance node groups
   - Cluster autoscaling

5. **Tools Module**
   - ArgoCD for GitOps
   - HashiCorp Vault integration
   - AWS IAM integration

### Infrastructure Diagram
```
┌─────────────┐     ┌──────────┐
│   Backend   │ ──> │   VPC    │
└─────────────┘     └──────────┘
                         │
                         ▼
                    ┌──────────┐
                    │   RDS    │
                    └──────────┘
                         │
                         ▼
                    ┌──────────┐
                    │   EKS    │
                    └──────────┘
                         │
                         ▼
                    ┌──────────┐
                    │  Tools   │
                    └──────────┘
```

### Design Decisions
- Modular architecture for maintainability
- Explicit module dependencies
- Environment-based deployments
- Sensitive data handling with variable marking
- Standardized AWS region across all modules

### Usage
1. Configure variables in `terraform.tfvars`
2. Initialize Terraform with backend configuration
3. Apply the configuration to deploy all modules

### Inputs
- `region`: AWS deployment region
- `environment`: Deployment environment (dev/stage/prod)
- `backend_bucket`: S3 bucket for state storage
- `vpc_configuration`: Network configuration object
- `db_configuration`: Database settings (sensitive)
- `eks_configuration`: Kubernetes cluster settings

### Outputs
- VPC identifiers
- Database endpoints
- EKS cluster access details
- ArgoCD access information
- Namespace information

### Notes
- Modules are versioned for stability
- Dependencies ensure correct deployment order
- Sensitive information is properly marked
- All modules share common variables (region, environment)

### Requirements
- Terraform >= 1.0.0, < 2.0.0
- AWS Provider ~> 5.0
- Valid AWS credentials
- S3 bucket for backend
