# Network outputs
output "vpc_id" {
  description = "ID of the created VPC"
  value       = module.vpc.vpc_id
}

# Database outputs
output "db_endpoint" {
  description = "Aurora cluster endpoint"
  value       = module.rds.db_endpoint
  sensitive   = true
}

# Kubernetes outputs
output "eks_endpoint" {
  description = "Kubernetes API server endpoint"
  value       = module.eks.cluster_endpoint
}

output "configure_kubectl" {
  description = "Command to configure kubectl"
  value       = module.eks.configure_kubectl
}

# Platform tools outputs
output "argocd_host" {
  description = "ArgoCD server hostname"
  value       = module.tools.argocd_host
}

output "namespaces" {
  description = "List of created Kubernetes namespaces"
  value       = module.tools.namespaces
}
