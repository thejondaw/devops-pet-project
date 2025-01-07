# Vault IAM role ARN for service account association
output "vault_role_arn" {
  description = "IAM role ARN for Vault"
  value       = aws_iam_role.vault.arn
}

# Add ArgoCD outputs
output "argocd_namespace" {
  description = "Namespace where ArgoCD is deployed"
  value       = helm_release.argocd.namespace
}

output "argocd_version" {
  description = "Deployed version of ArgoCD"
  value       = helm_release.argocd.version
}
