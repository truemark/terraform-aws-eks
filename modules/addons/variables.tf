variable "vpa_enabled" {
  description = "Enable Vertical Pod Autoscaler"
  type        = bool
  default     = false
}

variable "goldilocks_enabled" {
  description = "Enable Goldilocks operator"
  type        = bool
  default     = false
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
  }]
}
