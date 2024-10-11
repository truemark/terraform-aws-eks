variable "karpenter_controller_version" {
  description = "Version of karpenter controller to install"
  type        = string
}

variable "karpenter_crds_version" {
  description = "Version of karpenter's CRDs to install"
  type        = string
}

variable "enable_karpenter_controller_webhook" {
  description = "Enable or disable karpenter controller webhook"
  type        = bool
}

variable "enable_karpenter_crd_webhook" {
  description = "Enable or disable karpenter CRD webhook"
  type        = bool
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

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "oidc_provider_arn" {
  description = "OIDC provider ARN"
  type        = string
}

variable "cluster_endpoint" {
  description = "EKS cluster endpoint"
  type        = string
}

variable "aws_ecrpublic_authorization_token_user_name" {
  description = "ECR public authorization token user_name"
  type        = string
}

variable "aws_ecrpublic_authorization_token_user_password" {
  description = "ECR public authorization token password"
  type        = string
}
