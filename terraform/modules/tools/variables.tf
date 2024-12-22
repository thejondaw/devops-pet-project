# ==================================================== #
# ================ VARIABLES Of TOOLS ================ #
# ==================================================== #

# Variable - AWS Region
variable "region" {
  description = "AWS Region"
  type        = string
}

# Variable - Environment
variable "environment" {
  description = "Environment name (develop, stage, prod)"
  type        = string
  validation {
    condition     = contains(["app"], var.environment)
    error_message = "Environment must be develop, stage, or prod."
  }
}

# Variable - Environment Configuration - Namespaces
variable "environment_configuration" {
  description = "Environment configuration for namespaces"
  type = object({
    namespaces = list(string)
  })
  default = {
    namespaces = ["app"]
  }
  validation {
    condition     = length(var.environment_configuration.namespaces) > 0
    error_message = "At least one namespace must be specified."
  }
}

# Service configuration variable
variable "argocd_server_service" {
  description = "ArgoCD server service configuration"
  type = object({
    type                 = string
    load_balancer_type   = string
    cross_zone_enabled   = bool
    load_balancer_scheme = string
    source_ranges        = list(string)
  })
  default = {
    type                 = "LoadBalancer"
    load_balancer_type   = "nlb"
    cross_zone_enabled   = true
    load_balancer_scheme = "internet-facing"
    source_ranges        = ["0.0.0.0/0"]
  }
}

# ==================================================== #
