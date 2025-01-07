# ============= EKS CLUSTER ================ #
# Main EKS cluster
resource "aws_eks_cluster" "study" {
  name     = local.cluster_name
  role_arn = aws_iam_role.eks_cluster.arn
  version  = var.eks_configuration.version

  vpc_config {
    subnet_ids = [
      data.aws_subnet.web.id,
      data.aws_subnet.alb.id,
      data.aws_subnet.api.id
    ]
    endpoint_private_access = true
    #tfsec:ignore:aws-eks-no-public-cluster-access
    endpoint_public_access = true
    # public_access_cidrs  = ["YOUR.OFFICE.IP/32"]
    public_access_cidrs    = var.allowed_ips
    # Restrict EKS API access to specified IPs (e.g. VPN, office, CI/CD runners)
  }

  encryption_config {
    provider {
      key_arn = aws_kms_key.eks.arn
    }
    resources = ["secrets"]
  }

  enabled_cluster_log_types = [
    "api",
    "audit",
    "authenticator",
    "controllerManager",
    "scheduler"
  ]

  depends_on = [
    aws_cloudwatch_log_group.eks,
    aws_iam_role_policy_attachment.eks_cluster_policy
  ]

  tags = merge(local.common_tags, local.network_tags, {
    Name         = local.cluster_name
    ClusterType  = "EKS"
    Version      = var.eks_configuration.version
    Architecture = "Multi-AZ"
  })
}

# EKS node group configuration
resource "aws_eks_node_group" "study" {
  cluster_name    = aws_eks_cluster.study.name
  node_group_name = "${local.cluster_name}-nodes"
  node_role_arn   = aws_iam_role.node_group.arn
  capacity_type   = "SPOT"

  subnet_ids = [data.aws_subnet.web.id, data.aws_subnet.api.id]

  scaling_config {
    desired_size = var.eks_configuration.min_size
    max_size     = var.eks_configuration.max_size
    min_size     = var.eks_configuration.min_size
  }

  instance_types = var.eks_configuration.instance_types
  disk_size      = var.eks_configuration.disk_size

  update_config {
    max_unavailable = 1
  }

  depends_on = [
    aws_iam_role_policy_attachment.node_group_minimum_policies
  ]

  tags = merge(local.common_tags, local.compute_tags, {
    Name          = "${local.cluster_name}-node-group"
    NodeGroupType = "Application"
    InstanceType  = join(",", var.eks_configuration.instance_types)
    DiskSize      = "${var.eks_configuration.disk_size}GB"
    AutoScaling   = "Enabled"
  })
}
