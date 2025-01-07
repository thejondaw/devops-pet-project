# Output - Cluster - Endpoint
output "cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = aws_eks_cluster.study.endpoint
}

# Output - Cluster - Name
output "cluster_name" {
  description = "EKS cluster name"
  value       = aws_eks_cluster.study.name
}

# Output - kubectl - Config
output "configure_kubectl" {
  description = "Command to configure kubectl"
  value       = "aws eks update-kubeconfig --name ${aws_eks_cluster.study.name} --region ${data.aws_region.current.name}"
}

# Output - Cluster Certificate Authority
output "cluster_certificate_authority" {
  description = "Certificate authority data for cluster authentication"
  value       = aws_eks_cluster.study.certificate_authority[0].data
}
