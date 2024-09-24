variable "create" {
  description = "Create terraform release"
  type        = bool
  default     = true
}

variable "argocd" {
  description = "ArgoCD helm configuration"
  type        = any
  default     = {}
}

variable "install" {
  description = "Deploy ArgoCD helm"
  type        = bool
  default     = true
}

variable "cluster" {
  description = "ArgoCD cluster secrets"
  type        = any
  default     = null
  nullable    = true
}

variable "apps" {
  description = "ArgoCD apps of apps to deploy"
  type        = any
  default     = {}
}
