# =============== NGINX =============== #

# AWS Load Balancer setup through Nginx Ingress Controller
resource "helm_release" "ingress_nginx" {
  name             = "ingress-nginx"
  repository       = "https://kubernetes.github.io/ingress-nginx"
  chart            = "ingress-nginx"
  version          = "4.9.0"
  namespace        = "ingress-nginx"
  create_namespace = true

  values = [<<-EOF
    controller:
      # Prometheus metrics configuration
      metrics:
        enabled: true
        service:
          annotations:
            prometheus.io/scrape: "true"
            prometheus.io/port: "10254"

      # NLB configuration with AWS annotations
      service:
        enabled: true
        type: LoadBalancer
        annotations:
          service.beta.kubernetes.io/aws-load-balancer-type: "nlb"
          service.beta.kubernetes.io/aws-load-balancer-cross-zone-load-balancing-enabled: "true"
          service.beta.kubernetes.io/aws-load-balancer-scheme: "internet-facing"
          service.beta.kubernetes.io/aws-load-balancer-nlb-target-type: "ip"

      # Resource limits
      resources:
        requests:
          cpu: 25m
          memory: 48Mi
        limits:
          cpu: 50m
          memory: 96Mi

      # Proxy configuration and real IP handling
      config:
        use-forwarded-headers: "true"
        use-proxy-protocol: "false"
        enable-real-ip: "true"
        proxy-real-ip-cidr: "0.0.0.0/0"

      # Port configuration with proper mappings
      containerPort:
        http: 80
        https: 443
      service:
        ports:
          http: 80
          https: 443
        targetPorts:
          http: http
          https: https
    EOF
  ]
}

# ============== ArgoCD =============== #

# ArgoCD Installation and Configuration
resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = "5.51.6"
  namespace        = "argocd"
  create_namespace = true

  values = [<<-EOF
    global:
      image:
        imagePullPolicy: IfNotPresent

    server:
      extraArgs:
        - --insecure

      # Service configuration with explicit port mapping
      service:
        type: ClusterIP
        port: 80
        targetPort: 8080

      # Ingress configuration with proper backend routing
      ingress:
        enabled: true
        ingressClassName: nginx
        annotations:
          nginx.ingress.kubernetes.io/force-ssl-redirect: "false"
          nginx.ingress.kubernetes.io/ssl-redirect: "false"
          nginx.ingress.kubernetes.io/backend-protocol: "HTTP"
          nginx.ingress.kubernetes.io/proxy-body-size: "0"
        paths:
          - /
        pathType: Prefix
        backend:
          service:
            name: argocd-server
            port:
              number: 80
              targetPort: 8080

      # Resource allocation
      resources:
        limits:
          cpu: 100m
          memory: 128Mi
        requests:
          cpu: 50m
          memory: 64Mi

    # Redis configuration
    redis:
      resources:
        limits:
          cpu: 100m
          memory: 128Mi
        requests:
          cpu: 50m
          memory: 64Mi

    # Controller configuration
    controller:
      resources:
        limits:
          cpu: 200m
          memory: 256Mi
        requests:
          cpu: 100m
          memory: 128Mi

    # RepoServer configuration for better stability
    repoServer:
      resources:
        limits:
          cpu: 100m
          memory: 256Mi
        requests:
          cpu: 50m
          memory: 128Mi
    EOF
  ]

  depends_on = [
    helm_release.ingress_nginx
  ]
}

# resource "helm_release" "argocd" {
#   name             = "argocd"
#   repository       = "https://argoproj.github.io/argo-helm"
#   chart            = "argo-cd"
#   version          = "5.51.6"
#   namespace        = "argocd"
#   create_namespace = true

#   values = [<<-EOF
#     server:
#       extraArgs:
#         - --insecure
#       service:
#         type: ${var.argocd_server_service.type}
#         annotations:
#           service.beta.kubernetes.io/aws-load-balancer-type: "${var.argocd_server_service.load_balancer_type}"
#           service.beta.kubernetes.io/aws-load-balancer-cross-zone-load-balancing-enabled: "${var.argocd_server_service.cross_zone_enabled}"
#           service.beta.kubernetes.io/aws-load-balancer-scheme: "${var.argocd_server_service.load_balancer_scheme}"
#           service.beta.kubernetes.io/aws-load-balancer-nlb-target-type: "ip"
#           service.beta.kubernetes.io/aws-load-balancer-name: "argocd-${var.environment}-lb"
#         ports:
#           - name: http
#             port: 80
#             targetPort: 8080
#             protocol: TCP
#           - name: https
#             port: 443
#             targetPort: 8080
#             protocol: TCP
#         labels:
#           app: argocd
#           managedBy: terraform
#           service: argocd
#           component: server
#           environment: ${var.environment}
#         loadBalancerSourceRanges: ${jsonencode(var.argocd_server_service.source_ranges)}

#       rbac:
#         config:
#           policy.csv: |
#             p, role:org-admin, applications, *, */*, allow
#             p, role:org-admin, clusters, get, *, allow
#             p, role:org-admin, projects, get, *, allow

#       config:
#         repositories: |
#           - type: git
#             url: https://github.com/thejondaw/devops-pet-project.git
#             name: infrastructure

#     controller:
#       replicas: 1
#       resources:
#         limits:
#           cpu: 200m
#           memory: 256Mi
#         requests:
#           cpu: 100m
#           memory: 128Mi

#     redis:
#       resources:
#         limits:
#           cpu: 100m
#           memory: 128Mi
#         requests:
#           cpu: 50m
#           memory: 64Mi
#   EOF
#   ]
# }

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
