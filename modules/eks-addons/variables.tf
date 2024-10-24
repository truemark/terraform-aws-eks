variable "oidc_provider_arn" {
  description = "The ARN of the cluster OIDC Provider"
  type        = string
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


