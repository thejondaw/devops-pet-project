# ArgoCD - Helm
resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = "5.51.6"
  namespace        = "argocd"
  create_namespace = true

  values = [<<-EOF
    server:
      extraArgs:
        - --insecure
      service:
        type: ${var.argocd_server_service.type}
        annotations:
          service.beta.kubernetes.io/aws-load-balancer-type: "${var.argocd_server_service.load_balancer_type}"
          service.beta.kubernetes.io/aws-load-balancer-cross-zone-load-balancing-enabled: "${var.argocd_server_service.cross_zone_enabled}"
          service.beta.kubernetes.io/aws-load-balancer-scheme: "${var.argocd_server_service.load_balancer_scheme}"
          service.beta.kubernetes.io/aws-load-balancer-name: "argocd-${var.environment}-lb"
        labels:
          app: argocd
          managedBy: terraform
          service: argocd
          component: server
          environment: ${var.environment}
        loadBalancerSourceRanges: ${jsonencode(var.argocd_server_service.source_ranges)}

      rbac:
        config:
          policy.csv: |
            p, role:org-admin, applications, *, */*, allow
            p, role:org-admin, clusters, get, *, allow
            p, role:org-admin, projects, get, *, allow

      config:
        repositories: |
          - type: git
            url: https://github.com/thejondaw/devops-project.git
            name: infrastructure

    controller:
      replicas: 1
      resources:
        limits:
          cpu: 200m
          memory: 256Mi
        requests:
          cpu: 100m
          memory: 128Mi

    redis:
      resources:
        limits:
          cpu: 100m
          memory: 128Mi
        requests:
          cpu: 50m
          memory: 64Mi
  EOF
  ]
}
