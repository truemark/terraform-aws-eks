variable "cert_manager_chart_version" {
  description = "The version of the Helm chart to install."
  type        = string
  default     = "v1.13.3"

  validation {
    condition     = can(regex("^v1\\.(1[2-9]|[2-9][0-9])\\.[0-9]+$", var.cert_manager_chart_version))
    error_message = "The version must be v1.12.x or greater."
  }
}

variable "create_namespace" {
  description = "Create the namespace for cert-manager."
  type        = bool
  default     = true
}

variable "enable_recursive_nameservers" {
  description = "The recursive nameservers to use for DNS01 challenge."
  type        = bool
  default     = false
}

variable "recursive_nameservers" {
  description = "The recursive nameservers to use for DNS01 challenge."
  type        = string
  default     = "8.8.8.8:53\\,1.1.1.1:53"
}

variable "certmanager_node_selector" {
  description = "Config for node selector for workloads"
  type        = map(any)
  default = {
    CriticalAddonsOnly = "true"
  }
}

variable "certmanager_node_tolerations" {
  description = "Config for node tolerations for workloads"
  type        = list(any)
  default = [{
    key      = "CriticalAddonsOnly"
    operator = "Equal"
    effect   = "NoSchedule"
    value    = "true"
    }
  ]
}
