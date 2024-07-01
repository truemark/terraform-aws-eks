variable "region" {
  description = "The AWS region to deploy to."
  type        = string
}

variable "cluster_name" {
  description = "Name of the EKS cluster."
  type        = string
}

variable "amp_name" {
  description = "The AMP workspace name"
  type        = string
  default     = null
}

variable "amp_id" {
  description = "The AMP workspace id"
  type        = string
  default     = null
}

variable "amp_arn" {
  description = "The AMP workspace arn"
  type        = string
  default     = null
}

variable "oidc_provider_arn" {
  description = "The ARN of the OIDC Provider if `enable_irsa = true`"
  type        = string
}

variable "cluster_oidc_issuer_url" {
  description = "The URL on the EKS cluster for the OpenID Connect identity provider"
  type        = string
}

variable "alerts_sns_topics_arn" {
  description = "The ARN of the SNS topic to send alerts to"
  type        = string
}

variable "alert_role_arn" {
  description = "The ARN of the role to assume when sending alerts to SNS"
  type        = string
  default     = null
}

variable "tags" {
  description = "A map of tags to add to all resources."
  type        = map(string)
  default     = {}
}

variable "enable_alerts" {
  description = "Enable alerts"
  type        = bool
  default     = true
}

variable "prometheus_node_tolerations" {
  description = "K8S node tolerations for prometheus server"
  type        = map(any)
  default = {
    tolerations : []
  }
}
variable "prometheus_node_selector" {
  description = "K8S node selector for prometheus"
  type        = map(any)
  default = {
    nodeSelector : {}
  }
}

variable "prometheus_pvc_storage_size" {
  description = "Disk size for prometheus data storage"
  type        = string
  default     = "30Gi"
}

variable "monitoring_stack_enable_alertmanager" {
  description = "Enable on cluster alertmanager"
  type        = bool
  default     = false
}

variable "monitoring_stack_enable_pushgateway" {
  description = "Enable on cluster alertmanager"
  type        = bool
  default     = false
}

variable "prometheus_server_request_memory" {
  type        = string
  description = "Requested memory for prometheus instance"
  default     = "4Gi"
}

variable "prometheus_server_data_volume_size" {
  type        = string
  description = "Volume size for prometheus data"
  default     = "150Gi"
}

variable "amp_alerting_rules_exclude_namespace" {
  description = "Apply exclusion of namespace pattern defined"
  type        = string
  default     = ""
}

variable "amp_custom_alerting_rules" {
  description = "Prometheus K8s custom alerting rules"
  type        = string
  default     = ""
}
