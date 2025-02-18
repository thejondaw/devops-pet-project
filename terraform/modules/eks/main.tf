# Generate static timestamp for naming consistency
resource "time_static" "cluster_timestamp" {}

locals {
  # Format: env-clustername-YYYYMMDDHHMMSS
  cluster_name = "${var.environment}-cluster-${formatdate("YYYYMMDDHHmmss", time_static.cluster_timestamp.rfc3339)}"

  # Tags - All Resources
  common_tags = {
    Environment = var.environment
    ManagedBy   = "terra-m"
    Project     = "devops-pet-project"
    CreatedAt   = time_static.cluster_timestamp.rfc3339
    Owner       = "DevOps"
    Service     = "EKS"
  }

  # Tags - Network Resources
  network_tags = {
    NetworkType = "EKS-Network"
    VPCName     = "eks-vpc"
  }

  # Tags - Security Resources
  security_tags = {
    SecurityType = "EKS-Security"
    Compliance   = "HIPAA"
  }

  # Tags - Compute Resources
  compute_tags = {
    ComputeType = "EKS-Compute"
    Scheduler   = "kubernetes"
  }
}

# ================== IAM RESOURCES ================== #

# IAM Role - EKS Cluster
resource "aws_iam_role" "eks_cluster" {
  name = "${local.cluster_name}-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = merge(local.common_tags, local.security_tags, {
    Name = "${local.cluster_name}-role"
    Role = "EKS-Cluster"
  })
}

# Attach - Required Policy
resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster.name
}

# IAM Role - Node Group
resource "aws_iam_role" "node_group" {
  name = "${local.cluster_name}-node-group-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = merge(local.common_tags, local.security_tags, {
    Name = "${local.cluster_name}-node-group-role"
    Role = "EKS-NodeGroup"
  })
}

# Add proper IAM policy for EBS CSI Driver
resource "aws_iam_role_policy" "node_group_ebs" {
  name = "ebs-policy"
  role = aws_iam_role.node_group.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:CreateVolume",
          "ec2:DeleteVolume",
          "ec2:AttachVolume",
          "ec2:DetachVolume",
          "ec2:ModifyVolume",
          "ec2:CreateSnapshot",
          "ec2:DeleteSnapshot",
          "ec2:CreateTags"
        ]
        Resource = [
          "arn:aws:ec2:${var.region}:${data.aws_caller_identity.current.account_id}:volume/*",
          "arn:aws:ec2:${var.region}:${data.aws_caller_identity.current.account_id}:snapshot/*",
          "arn:aws:ec2:${var.region}:${data.aws_caller_identity.current.account_id}:instance/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeVolumes",
          "ec2:DescribeVolumesModifications",
          "ec2:DescribeSnapshots",
          "ec2:DescribeTags",
          "ec2:DescribeInstances"
        ]
        Resource = "*"
      }
    ]
  })
}

# Attach - Required Policies - Node Group
resource "aws_iam_role_policy_attachment" "node_group_minimum_policies" {
  for_each = toset([
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  ])

  policy_arn = each.value
  role       = aws_iam_role.node_group.name
}

# ================ CLOUDWATCH LOGS ================== #

# CloudWatch - Log Group - EKS
resource "aws_cloudwatch_log_group" "eks" {
  name              = "/aws/eks/${local.cluster_name}/cluster"
  retention_in_days = 7

  tags = merge(local.common_tags, {
    Name      = "${local.cluster_name}-logs"
    LogType   = "EKS-Cluster-Logs"
    Retention = "7-days"
  })
}

# ================== EKS CLUSTER =================== #

# EKS Cluster
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
    endpoint_public_access  = true
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

# =================== NODE GROUP =================== #

# EKS - Node Group
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
