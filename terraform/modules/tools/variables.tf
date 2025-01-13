# Variable - AWS Region
variable "region" {
  description = "AWS Region"
  type        = string
}

# Variable - Environment
variable "environment" {
  description = "Environment name (develop, stage, master)"
  type        = string
  validation {
    condition     = contains(["develop", "stage", "master"], var.environment)
    error_message = "Environment must be develop, stage, or master."
  }
}

# Variable - ArgoCD Service
# variable "argocd_server_service" {
#   description = "ArgoCD server service configuration"
#   type = object({
#     type                 = string
#     load_balancer_type   = string
#     cross_zone_enabled   = bool
#     load_balancer_scheme = string
#     source_ranges        = list(string)
#   })
#   default = {
#     type                 = "LoadBalancer"
#     load_balancer_type   = "nlb"
#     cross_zone_enabled   = true
#     load_balancer_scheme = "internet-facing"
#     source_ranges        = ["0.0.0.0/0"]
#   }
# }
