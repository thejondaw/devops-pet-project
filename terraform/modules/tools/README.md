## Tools Module

### Overview
Deploys essential operational tools in EKS cluster.

### Key Features
- ArgoCD for GitOps
- Vault for secrets management
- OIDC integration with AWS IAM
- Load balancer configuration
- RBAC policies

### Resources Created
- ArgoCD Helm release
- Vault IAM roles
- Load balancer for ArgoCD UI
- RBAC configurations
- Security groups

### Design Decisions
- ArgoCD for GitOps workflow
- NLB for ArgoCD access (better for WebSocket)
- IAM roles with least privilege
- Environment-based access control
