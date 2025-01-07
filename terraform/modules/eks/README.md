## EKS Module

### Overview
Deploys a production-ready EKS cluster with security best practices.

### Key Features
- Multi-AZ deployment
- Spot instances for cost optimization
- KMS encryption for secrets
- ClusterAutoscaler support
- CloudWatch logging
- OIDC integration

### Resources Created
- EKS cluster
- Node group with spot instances
- IAM roles and policies
- KMS keys
- CloudWatch log groups
- Security groups

### Design Decisions
- Spot instances for cost reduction
- Private endpoint access for security
- CloudWatch logging for all control plane components
- KMS encryption for Kubernetes secrets
- OIDC provider for pod IAM roles
