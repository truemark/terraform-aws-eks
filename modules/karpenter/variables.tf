variable "karpenter_controller_version" {
  description = "Version of karpenter controller to install"
  type        = string
}

variable "karpenter_crds_version" {
  description = "Version of karpenter's CRDs to install"
  type        = string
}

variable "karpenter_settings_featureGates_drift" {
  type        = bool
  description = "Enable or disable drift feature of karpenter"
}

variable "critical_addons_node_selector" {
  description = "Config for node selector for workloads"
  type        = map(any)
}

variable "critical_addons_node_tolerations" {
  description = "Config for node tolerations for workloads"
  type        = list(any)
}

variable "tags" {
  description = "A map of tags to add to all resources."
  type        = map(string)
}
