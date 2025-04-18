variable "tags" {
  description = "A map of tags to add to all resources."
  type        = map(string)
  default     = {}
}

variable "cluster_name" {
  description = "Name of the EKS cluster."
  type        = string
}

variable "cluster_security_group_id" {
  description = "Security group ID of the EKS cluster"
  type        = string
}

variable "node_security_group_id" {
  description = "Security group ID of the EKS Nodes"
  type        = string
}

variable "vpc_id" {
  description = "AWS VPC ID"
  type        = string
}

variable "cluster_endpoint" {
  description = "Endpoint for your Kubernetes API server."
  type        = string
}

variable "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data required to communicate with your cluster."
  type        = string
}

variable "cluster_token" {
  description = "Authentication token for the EKS cluster."
  type        = string
}

variable "cluster_version" {
  description = "Kubernetes `<major>.<minor>` version to use for the EKS cluster (i.e.: `1.24`)."
  type        = string
}

variable "oidc_provider_arn" {
  description = "The ARN of the cluster OIDC Provider."
  type        = string
}

variable "create_delay_duration" {
  description = "The duration to wait before creating resources."
  type        = string
  default     = "30s"
}

variable "create_delay_dependencies" {
  description = "Dependency attribute which must be resolved before starting the `create_delay_duration`."
  type        = list(string)
  default     = []
}

variable "enable_eks_fargate" {
  description = "Identifies whether or not respective addons should be modified to support deployment on EKS Fargate."
  type        = bool
  default     = false
}

variable "critical_addons_node_selector" {
  description = "Config for node selector for workloads."
  type        = map(any)
}

variable "critical_addons_node_affinity" {
  description = "Config for node tolerations for workloads"
  type        = map(any)
  default = {
    nodeAffinity = {
      preferredDuringSchedulingIgnoredDuringExecution = {
        nodeSelectorTerms = [
          {
            weight = 1,
            preference = {
              matchExpressions = [
                {
                  key      = "CriticalAddonsOnly"
                  operator = "In"
                  values   = ["true"]
                }
              ]
            }
          },
          {
            weight = 2,
            preference = {
              matchExpressions = [
                {
                  key      = "karpenter.sh/nodepool"
                  operator = "In"
                  values   = ["system", "truemark-system"]
                }
              ]
            }
          }
        ]
      }
    }
  }
}

variable "critical_addons_node_tolerations" {
  description = "Config for node tolerations for workloads."
  type        = list(any)
}

variable "auto_mode_system_nodes_config" {
  description = "Kubernetes manifest with system node pool configuration"
  default     = {}
}

variable "aws_partition" {}
variable "aws_region" {}
variable "aws_account_id" {}

################################################################################
# GitOps Bridge
################################################################################
variable "create_kubernetes_resources" {
  description = "Create Kubernetes resource with Helm or Kubernetes provider."
  type        = bool
  default     = false
}

variable "enable_cert_manager" {
  description = "Flag to enable or disable the cert-manager add-on."
  type        = bool
  default     = false
}

variable "enable_external_dns" {
  description = "Flag to enable or disable the External DNS add-on."
  type        = bool
  default     = false
}

variable "enable_external_secrets" {
  description = "Flag to enable or disable the External Secrets operator add-on."
  type        = bool
  default     = false
}

variable "enable_metrics_server" {
  description = "Enable External Secrets operator add-on."
  type        = bool
  default     = false
}

variable "enable_aws_load_balancer_controller" {
  description = "Enable AWS Load Balancer Controller add-on."
  type        = bool
  default     = false
}

variable "enable_karpenter" {
  description = "Flag to enable or disable the Karpenter controller add-on."
  type        = bool
  default     = false
}

variable "enable_auto_mode" {
  description = "Flag to enable or disable the auto_mode controller add-on."
  type        = bool
  default     = false
}

variable "enable_keda" {
  description = "Enable Keda add-on."
  type        = bool
  default     = false
}

variable "enable_velero" {
  description = "Enable Kubernetes Dashboard add-on."
  type        = bool
  default     = false
}

variable "enable_aws_ebs_csi_resources" {
  description = "Flag to enable or disable the AWS EBS CSI resources add-on."
  type        = bool
  default     = false
}

variable "enable_kube_bench" {
  description = "Flag to enable or disable the enable_kube_bench security scanner add-ons."
  type        = bool
  default     = false
}

variable "enable_observability" {
  description = "Flag to enable or disable the observability.thanos controller add-on."
  type        = bool
  default     = false
}

variable "observability_helm_config" {
  description = "Configuration for the Observability add-on."
  type        = any
  default     = {}
}

variable "kube_bench_helm_config" {
  description = "Configuration for the kube-bench add-on."
  type        = any
  default     = {}
}

variable "deploy_addons" {
  description = "Flag to enable or disable the observability.thanos controller add-on."
  type        = bool
  default     = true
}
