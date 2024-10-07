
variable "snapshotter_version" {
  description = "Version of external-snapshotter to install"
  type        = string
  default     = "v8.1.0"
  validation {
    condition     = can(regex("^v[0-9]+\\.[0-9]+\\.[0-9]+$", var.snapshotter_version))
    error_message = "The snapshotter_version tag must start with 'v' followed by a valid semantic version (e.g., v1.2.3)."
  }
}

variable "node_selector" {
  description = "Config for node selector for workloads"
  type        = map(any)
  default = {
    CriticalAddonsOnly = "true"
  }
}

variable "node_tolerations" {
  description = "Config for node tolerations for workloads"
  type        = list(any)
  default = [
    {
      key      = "CriticalAddonsOnly"
      operator = "Equal"
      effect   = "NoSchedule"
      value    = "true"
    }
  ]
}
