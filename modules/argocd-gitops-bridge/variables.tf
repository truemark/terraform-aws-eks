variable "create" {
  description = "Create terraform resources"
  type        = bool
  default     = true
}
variable "argocd" {
  description = "argocd helm options"
  type        = any
  default     = {}
}
variable "install" {
  description = "Deploy argocd helm"
  type        = bool
  default     = true
}

variable "cluster" {
  description = "argocd cluster secret"
  type        = any
  default     = null
}

variable "apps" {
  description = "argocd app of apps to deploy"
  type        = any
  default     = {}
}


variable "argocd_access_url" {
  description = "External access URL for ArgoCD UI (e.g., https://argocd.example.com)"
  type        = string
  default     = null
}

variable "argocd_dex_configs" {
  description = <<EOT
YAML-formatted string for configuring ArgoCD Dex connectors.
Should be a valid YAML string (not a map).
Example:
  connectors:
    - type: oidc
      id: oidc
      name: Auth0
      config:
        issuer: https://example.auth0.com
        clientID: my-client-id
        clientSecret: my-secret
EOT
  type        = string
  default     = null
}

variable "argocd_rbac_policy_csv" {
  description = <<EOT
RBAC policy configuration in CSV format for ArgoCD.
Should be a plain string in CSV format.
Example:
  g, user@example.com, role:admin
  g, team@example.com, role:read-only
EOT
  type        = string
  default     = null
}

variable "critical_addons_node_affinity" {
  description = "Node affinity rules for critical add-ons."
  type        = any
  default = {
    nodeAffinity = {
      preferredDuringSchedulingIgnoredDuringExecution = {
        nodeSelectorTerms = [
          {
            weight = 1
            preference = {
              matchExpressions = [
                {
                  key      = "CriticalAddonsOnly"
                  operator = "Equals"
                  values   = ["true"]
                }
              ]
            }
          },
          {
            weight = 2
            preference = {
              matchExpressions = [
                {
                  key      = "karpenter.sh/nodepool"
                  operator = "In"
                  values   = ["system", "truemark-system"]
                }
              ]
            }
          }
        ]
      }
    }
  }
}

variable "critical_addons_node_tolerations" {
  description = "List of tolerations required for critical add-ons."
  type        = any
  default = [
    {
      key      = "CriticalAddonsOnly"
      operator = "Exists"
      effect   = "NoSchedule"
    }
  ]
}
