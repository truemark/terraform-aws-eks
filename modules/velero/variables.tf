variable "cluster_name" {
  description = "The name of the EKS cluster"
  type        = string
}

variable "velero_chart_version" {
  description = "The version of the Velero Helm chart to install"
  type        = string
  default     = "7.2.1"
}

variable "oidc_issuer_url" {
  type        = string
  description = "OIDC issuer url"
}

variable "s3_bucket_name" {
  type        = string
  description = "S3 bucket for backups name"
}

variable "critical_addons_node_selector" {
  description = "Config for node selector for workloads"
  type        = map(any)
  default = {
    CriticalAddonsOnly = "true"
  }
}

variable "critical_addons_node_tolerations" {
  description = "Config for node tolerations for workloads"
  type        = list(any)
  default = [{
    key      = "CriticalAddonsOnly"
    operator = "Equal"
    effect   = "NoSchedule"
    value    = "true"
    },
    {
      key      = "karpenter.sh/nodepool"
      value    = "truemark-amd64"
      operator = "Equal"
      effect   = "NoSchedule"
    },
    {
      key      = "karpenter.sh/nodepool"
      value    = "truemark-arm64"
      operator = "Equal"
      effect   = "NoSchedule"
    }
  ]
}
