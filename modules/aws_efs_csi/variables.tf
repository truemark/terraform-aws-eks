variable "chart_version" {
  type        = string
  default     = "3.0.8"
  description = "The version of aws-efs-csi-driver chart"
}

variable "chart_name" {
  type        = string
  default     = "aws-efs-csi-driver"
  description = "Helm chart name"
}

variable "helm_repo_name" {
  type        = string
  description = "Helm repository url."
  default     = "https://kubernetes-sigs.github.io/aws-efs-csi-driver/"
}

variable "oidc_issuer_url" {
  type        = string
  description = "OIDC issuer url"
}

variable "cluster_name" {
  type = string
}

variable "release_name" {
  type        = string
  default     = "aws-efs-csi-driver"
  description = "The name of the aws-efs-csi-driver helm release"
}

