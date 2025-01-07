# AWS deployment region
variable "region" {
  description = "AWS Region for resource deployment"
  type        = string
}

# Environment name validation
variable "environment" {
  description = "Environment name (app only for tools module)"
  type        = string
  validation {
    condition     = contains(["app"], var.environment)
    error_message = "Environment must be 'app' for tools module."
  }
}

# ArgoCD service configuration
variable "argocd_server_service" {
  description = "ArgoCD server service configuration"
  type = object({
    type                 = string       # Service type (LoadBalancer)
    load_balancer_type   = string       # AWS LB type (nlb/alb)
    cross_zone_enabled   = bool         # Enable cross-AZ load balancing
    load_balancer_scheme = string       # internal/internet-facing
    source_ranges        = list(string) # Allowed CIDR blocks
  })

  default = {
    type                 = "LoadBalancer"
    load_balancer_type   = "nlb"
    cross_zone_enabled   = true
    load_balancer_scheme = "internet-facing"
    source_ranges        = ["0.0.0.0/0"]
  }

  validation {
    condition     = contains(["internet-facing", "internal"], var.argocd_server_service.load_balancer_scheme)
    error_message = "Load balancer scheme must be 'internet-facing' or 'internal'."
  }

  validation {
    condition     = contains(["nlb", "alb"], var.argocd_server_service.load_balancer_type)
    error_message = "Load balancer type must be 'nlb' or 'alb'."
  }
}

# Common tags for resources
locals {
  common_tags = {
    Environment = var.environment
    Project     = "devops-project"
    ManagedBy   = "terraform"
    Component   = "tools"
  }
}
