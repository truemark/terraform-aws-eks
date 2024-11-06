variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "cluster_endpoint" {
  description = "Endpoint for your Kubernetes API server"
  type        = string
}

variable "cluster_version" {
  description = "Kubernetes `<major>.<minor>` version to use for the EKS cluster (i.e.: `1.24`)"
  type        = string
}

variable "oidc_provider_arn" {
  description = "The ARN of the cluster OIDC Provider"
  type        = string
}

variable "create_delay_duration" {
  description = "The duration to wait before creating resources"
  type        = string
  default     = "30s"
}

variable "create_delay_dependencies" {
  description = "Dependency attribute which must be resolved before starting the `create_delay_duration`"
  type        = list(string)
  default     = []
}

variable "enable_eks_fargate" {
  description = "Identifies whether or not respective addons should be modified to support deployment on EKS Fargate"
  type        = bool
  default     = false
}

variable "aws_partition" {}
variable "aws_region" {}
variable "aws_account_id" {}

################################################################################
# GitOps Bridge
################################################################################
variable "create_kubernetes_resources" {
  description = "Create Kubernetes resource with Helm or Kubernetes provider"
  type        = bool
  default     = false
}
