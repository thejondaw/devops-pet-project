# ==================================================== #
# =================== TOOLS MODULE =================== #
# ==================================================== #

# Provider - Terraform
terraform {
  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.11.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23.0"
    }
  }
}

# Provider - Kubernetes
provider "kubernetes" {
  host                   = var.cluster_configuration.endpoint
  cluster_ca_certificate = base64decode(var.cluster_configuration.certificate)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", var.cluster_configuration.name]
  }
}

# Provider - Helm
provider "helm" {
  kubernetes {
    host                   = var.cluster_configuration.endpoint
    cluster_ca_certificate = base64decode(var.cluster_configuration.certificate)

    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      args        = ["eks", "get-token", "--cluster-name", var.cluster_configuration.name]
      command     = "aws"
    }
  }
}

# =================== DATA SOURCES =================== #

# Fetch - EKS Cluster - Auth
data "aws_eks_cluster_auth" "cluster" {
  name = var.cluster_configuration.name
}

# Fetch - EKS Cluster
data "aws_eks_cluster" "cluster" {
  name = var.cluster_configuration.name
}

# =================== HELM CHARTS ==================== #

# Helm Repository - ArgoCD
resource "helm_repository" "argo" {
  name = "argo"
  url  = "https://argoproj.github.io/argo-helm"
}

# Install - ArgoCD
resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = helm_repository.argo.metadata[0].name
  chart            = "argo-cd"
  version          = "5.51.6"
  namespace        = "argocd"
  create_namespace = true

  values = [
    file("${path.module}/values/argocd-values.yaml")
  ]

  depends_on = [
    kubernetes_namespace.argocd
  ]
}

# =================== NAMESPACES ==================== #

# ArgoCD - Namespace
resource "kubernetes_namespace" "argocd" {
  metadata {
    name = "argocd"
    labels = {
      name = "argocd"
      type = "system"
    }
  }
}

# Application - Namespaces
resource "kubernetes_namespace" "applications" {
  for_each = toset(var.environment_configuration.namespaces)

  metadata {
    name = each.key
    labels = {
      environment = each.key
      managed-by  = "terraform"
    }
  }
}

# =============== NETWORK POLICIES ================== #

# Network Policies - Default
resource "kubernetes_network_policy" "default" {
  for_each = kubernetes_namespace.applications

  metadata {
    name      = "default-deny"
    namespace = each.value.metadata[0].name
  }

  spec {
    pod_selector {}
    policy_types = ["Ingress", "Egress"]

    ingress {
      from {
        namespace_selector {
          match_labels = {
            environment = each.value.metadata[0].name
          }
        }
      }
    }

    egress {
      to {
        ip_block {
          cidr = "0.0.0.0/0"
        }
      }
    }
  }
}

# ================= RBAC Resources ================== #

#  ArgoCD Admin - ClusterRole
resource "kubernetes_cluster_role" "argocd_admin" {
  metadata {
    name = "argocd-admin-role"
  }

  rule {
    api_groups = ["*"]
    resources  = ["*"]
    verbs      = ["*"]
  }
}

# ArgoCD Admin - ClusterRoleBinding
resource "kubernetes_cluster_role_binding" "argocd_admin" {
  metadata {
    name = "argocd-admin-role-binding"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.argocd_admin.metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = "argocd-application-controller"
    namespace = "argocd"
  }
}

# ==================================================== #
