# Get AWS account and region info
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# Generate timestamp for resource naming
resource "time_static" "cluster_timestamp" {}

locals {
  # Cluster name with timestamp for uniqueness
  cluster_name = "${var.environment}-cluster-${formatdate("YYYYMMDDHHmmss", time_static.cluster_timestamp.rfc3339)}"

  # Resource tagging strategy
  common_tags = {
    Environment = var.environment
    ManagedBy   = "terra-m"
    Project     = "devops-project"
    CreatedAt   = time_static.cluster_timestamp.rfc3339
    Owner       = "DevOps"
    Service     = "EKS"
    Region      = data.aws_region.current.name
    Account     = data.aws_caller_identity.current.account_id
  }

  network_tags = {
    NetworkType = "EKS-Network"
    VPCName     = "eks-vpc"
  }

  security_tags = {
    SecurityType = "EKS-Security"
    Compliance   = "HIPAA"
    Encryption   = "AES256"
  }

  compute_tags = {
    ComputeType = "EKS-Compute"
    Scheduler   = "kubernetes"
  }
}
