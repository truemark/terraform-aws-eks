variable "addons_context" {
  description = "Context for the add-ons."
  type        = any
}

variable "tags" {
  description = "Tags to apply to the resources."
  type        = map(string)
  default     = {}
}

variable "kube_bench_helm_config" {
  description = "Configuration for the kube-bench add-on."
  type        = any
  default     = {}
}
