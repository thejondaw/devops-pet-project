# ============== ArgoCD =============== #

# ArgoCD - Helm
resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = "5.51.6"

  values = [<<-EOF
    global:
      image:
        imagePullPolicy: Always

    server:
      extraArgs:
        - --insecure
      service:
        type: LoadBalancer
        annotations:
          service.beta.kubernetes.io/aws-load-balancer-type: "nlb"
          service.beta.kubernetes.io/aws-load-balancer-internal: "false"
          service.beta.kubernetes.io/aws-load-balancer-scheme: "internet-facing"
          # Добавил explicit ports
        ports:
          - name: http
            port: 80
            targetPort: 8080
          - name: https
            port: 443
            targetPort: 8080

      # Важная хуйня для безопасности
      config:
        url: https://argocd.your-domain.com  # Замени на свой домен
        admin.enabled: "true"
        application.instanceLabelKey: argocd.argoproj.io/instance

    # Redis configuration
    redis:
      enabled: true

    # Repo server configuration
    repoServer:
      serviceAccount:
        create: true

    # Application controller
    controller:
      serviceAccount:
        create: true
  EOF
  ]

  # Добавляем тайм-аут для деплоя
  timeout = 800
  wait    = true
}

# ========== HashiCorp Vault ========== #

# IAM Role - Vault
resource "aws_iam_role" "vault" {
  name = "${var.environment}-vault-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${replace(data.aws_eks_cluster.cluster.identity[0].oidc[0].issuer, "https://", "")}"
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${replace(data.aws_eks_cluster.cluster.identity[0].oidc[0].issuer, "https://", "")}:sub" : [
              "system:serviceaccount:vault:vault",
              "system:serviceaccount:kube-system:ebs-csi-controller-sa"
            ]
          }
        }
      }
    ]
  })
}

# Get current AWS account
data "aws_caller_identity" "current" {}

# IAM Policy for Vault secrets and EBS operations
resource "aws_iam_role_policy" "vault_secrets" {
  name = "${var.environment}-vault-secrets-policy"
  role = aws_iam_role.vault.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        # Restrict Secrets Manager access to specific environment paths
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = [
          "arn:aws:secretsmanager:${var.region}:${data.aws_caller_identity.current.account_id}:secret:${var.environment}/*",
          "arn:aws:secretsmanager:${var.region}:${data.aws_caller_identity.current.account_id}:secret:${var.environment}-*"
        ]
      },
      {
        # EBS operations limited by environment tag
        Effect = "Allow"
        Action = [
          "ec2:CreateSnapshot",
          "ec2:AttachVolume",
          "ec2:DetachVolume",
          "ec2:ModifyVolume"
        ]
        Resource = [
          "arn:aws:ec2:${var.region}:${data.aws_caller_identity.current.account_id}:volume/*",
          "arn:aws:ec2:${var.region}:${data.aws_caller_identity.current.account_id}:snapshot/*"
        ]
        Condition = {
          StringEquals = {
            "aws:ResourceTag/Environment" = var.environment
          }
        }
      },
      {
        # Read-only EC2 operations - safe to allow on all resources
        Effect = "Allow"
        Action = [
          "ec2:DescribeAvailabilityZones",
          "ec2:DescribeInstances",
          "ec2:DescribeSnapshots",
          "ec2:DescribeTags",
          "ec2:DescribeVolumes",
          "ec2:DescribeVolumesModifications"
        ]
        Resource = "*"
      }
    ]
  })
}
