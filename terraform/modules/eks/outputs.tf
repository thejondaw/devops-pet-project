# ================== OUTPUTS ================== #
# Cluster endpoint for kubectl configuration
output "cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = aws_eks_cluster.study.endpoint
}

# Cluster name for reference
output "cluster_name" {
  description = "EKS cluster name"
  value       = aws_eks_cluster.study.name
}

# kubectl configuration command
output "configure_kubectl" {
  description = "Command to configure kubectl"
  value       = "aws eks update-kubeconfig --name ${aws_eks_cluster.study.name} --region ${data.aws_region.current.name}"
}

# Cluster CA certificate for authentication
output "cluster_certificate_authority" {
  description = "Certificate authority data for cluster authentication"
  value       = aws_eks_cluster.study.certificate_authority[0].data
}
