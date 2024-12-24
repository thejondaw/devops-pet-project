# ==================================================== #
# ================= OUTPUTS Of ROOT ================== #
# ==================================================== #

# Output - VPC - ID
output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

# Output - DB - Endpoint
output "db_endpoint" {
  description = "Database endpoint"
  value       = module.rds.db_endpoint
}

# Output - EKS - Endpoint
output "eks_endpoint" {
  description = "Kubernetes API endpoint"
  value       = module.eks.cluster_endpoint
}

# Output - kubectl - Config
output "configure_kubectl" {
  description = "Command to configure kubectl"
  value       = module.eks.configure_kubectl
}

# Output - ArgoCD - Host
output "argocd_host" {
  description = "ArgoCD server hostname"
  value       = module.tools.argocd_host
}

# Output - Namespaces
output "namespaces" {
  description = "Created namespaces"
  value       = module.tools.namespaces
}

# ==================================================== #
