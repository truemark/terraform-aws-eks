
variable "chart_version" {
  description = "Version of external-snapshotter to install"
  type        = string
  default     = "3.4.0"
  validation {
    condition     = can(regex("^[0-9]+\\.[0-9]+\\.[0-9]+$", var.chart_version))
    error_message = "The chart_version tag must start with 'v' followed by a valid semantic version (e.g., v1.2.3)."
  }
}

variable "namespace" {
  description = "Namespace to install snapshotter"
  type        = string
  default     = "snapscheduler"
}

variable "node_tolerations" {
  description = "Config for node tolerations for workloads"
  type        = list(any)
  default = [
    {
      key      = "karpenter.sh/nodepool"
      value    = "truemark-amd64"
      operator = "Equal"
      effect   = "NoSchedule"
    }
  ]
}


