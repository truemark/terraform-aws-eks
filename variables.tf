###############################################
# General Cluster Configuration
###############################################

variable "tags" {
  description = "A map of tags to add to all resources."
  type        = map(string)
  default     = {}
}

variable "cluster_name" {
  description = "Name of the EKS cluster."
  type        = string
  default     = ""
}

variable "subnets_ids" {
  description = "A list of subnet IDs where the nodes/node groups will be provisioned."
  type        = list(string)
  default     = []
}

variable "vpc_id" {
  description = "ID of the VPC where the cluster and its nodes will be provisioned."
  type        = string
  default     = null
}

variable "cluster_endpoint_private_access" {
  description = "Indicates whether or not the Amazon EKS private API server endpoint is enabled."
  type        = bool
  default     = true
}

variable "cluster_endpoint_public_access" {
  description = "Indicates whether or not the Amazon EKS public API server endpoint is enabled."
  type        = bool
  default     = false
}

variable "cluster_version" {
  description = "Kubernetes `<major>.<minor>` version to use for the EKS cluster (i.e.: `1.24`)"
  type        = string
  default     = "1.29"
}

variable "enable_cluster_creator_admin_permissions" {
  description = "Enable cluster creator admin permissions"
  type        = bool
  default     = false
}

variable "create_cloudwatch_log_group" {
  description = "Create a CloudWatch log group for the EKS cluster"
  type        = bool
  default     = true
}

variable "bootstrap_self_managed_addons" {
  description = "Indicates whether to bootstrap self-managed add-ons for the EKS cluster."
  type        = bool
  default     = true
}

###############################################
# EKS Addons Configuration
###############################################
variable "vpc_cni_before_compute" {
  description = "Whether to install the VPC CNI before the compute resources."
  type        = bool
  default     = false
}

variable "enable_guard_duty" {
  description = "Enable Guard Duty addon"
  type        = bool
  default     = false
}

variable "guard_duty_addon_version" {
  description = "Version of the Guard Duty addon to install"
  type        = string
  default     = null
  nullable    = true
}

################################################################################
# Compute Resources
################################################################################
variable "compute_mode" {
  description = <<EOF
Description:
Specifies the compute provider to use for the EKS. Must be one of the following modes:

- eks_auto_mode: Use EKS managed node groups.
- karpenter: Use Karpenter for provisioning nodes.
EOF
  type        = string
  validation {
    condition     = contains(["eks_auto_mode", "karpenter"], var.compute_mode)
    error_message = "Invalid compute mode. Must be either eks_auto_mode or karpenter"
  }
}

variable "auto_mode_system_nodes_config" {
  description = "Contains configuration for system nodepool and nodeclass"
  type = object({
    nodepool_name  = string
    nodeclass_name = string
    nodepool_limits = optional(object({
      cpu    = optional(string, "64")
      memory = optional(string, "64gi")
    }))
    instance_category                 = optional(list(string), ["c", "m", "r"])
    instance_cpu                      = optional(list(string), ["2", "4", "8"])
    instance_hypervisor               = optional(list(string), ["nitro"])
    instance_arch                     = optional(list(string), ["amd64"])
    instance_capacity_type            = optional(list(string), ["spot"])
    instance_termination_grace_period = optional(string, "24h0m0s")
    instance_expire_after             = optional(string, "480h")
    instance_generation               = optional(string, "4")
  })
  default = {
    nodepool_name = "truemark-system"
    nodepool_limits = {
      cpu    = "64"
      memory = "64Gi"
    }
    nodeclass_name                    = "truemark-system"
    instance_capacity_type            = ["spot"]
    instance_category                 = ["c", "m", "r"]
    instance_cpu                      = ["2", "4", "8"]
    instance_hypervisor               = ["nitro"]
    instance_arch                     = ["amd64"]
    instance_generation               = "4"
    instance_termination_grace_period = "24h0m0s"
    instance_expire_after             = "480h"
  }
}

variable "eks_managed_node_groups" {
  description = "Map of EKS managed node group definitions to create."
  type        = any
  default     = {}
}

variable "create_default_critical_addon_node_group" {
  description = "Create a default critical addon node group"
  type        = bool
  default     = false
}

variable "default_critical_addon_node_group_instance_types" {
  description = "Instance type for the default critical addon node group"
  type        = list(string)
  default     = ["m7g.large"]
}

variable "default_critical_nodegroup_kms_key_id" {
  description = "KMS key ID for the default critical addon node group"
  type        = string
  default     = null
  nullable    = true
}

variable "default_critical_addon_capacity_type" {
  description = "Capacity type for the default critical addon node group"
  type        = string
  default     = "ON_DEMAND"
}

variable "critical_addons_node_selector" {
  description = "Config for node selector for workloads"
  type        = map(any)
  default = {
    "CriticalAddonsOnly" = "true"
  }
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
                  operator = "Equals"
                  values   = "\"true\""
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
  description = "Config for node tolerations for workloads"
  type        = list(map(string))
  default = [{
    key      = "CriticalAddonsOnly"
    operator = "Exists"
    effect   = "NoSchedule"
  }]
}

variable "eks_managed_node_group_defaults" {
  description = "Map of EKS managed node group default configurations."
  type        = any
  default     = {}
}

variable "cluster_security_group_additional_rules" {
  description = "List of additional security group rules to add to the cluster security group created. Set `source_node_security_group = true` inside rules to set the `node_security_group` as source"
  type        = any
  default     = {}
}

variable "node_security_group_additional_rules" {
  description = "List of additional security group rules to add to the node security group created. Set `source_cluster_security_group = true` inside rules to set the `cluster_security_group` as source"
  type        = any
  default     = {}
}

variable "cluster_additional_security_group_ids" {
  description = "List of additional, externally created security group IDs to attach to the cluster control plane"
  type        = list(string)
  default     = []
}

###############################################
# EKS Access Configuration
###############################################
variable "eks_access_account_iam_roles" {
  description = "AWS IAM roles that will be mapped to RBAC roles."
  type = list(object({
    role_name = string,
    access_scope = object({
      type       = string
      namespaces = list(string)
    })
    policy_name = string
  }))
  default = []
}

variable "eks_access_cross_account_iam_roles" {
  description = "AWS IAM roles that will be mapped to RBAC roles."
  type = list(object({
    role_name = string
    account   = string
    access_scope = object({
      type       = string
      namespaces = list(string)
    })
    prefix      = string
    policy_name = string
  }))
  default = []
}

###############################################
# EKS Addons Configuration
###############################################
variable "addons_repo_url" {
  description = "URL of the EKS Addons Helm repository."
  type        = string
  default     = "https://github.com/truemark/terraform-aws-eks"
}

variable "addons_target_revision" {
  description = "The target revision of the EKS Addons Helm repository."
  type        = string
  default     = "main"
}

variable "addons_repo_path" {
  description = "Path to the EKS Addons Helm repository."
  type        = string
  default     = "bootstrap/charts/eks-addons"
}

variable "workloads_argocd_apps" {
  description = "ArgoCD workload applications to deploy."
  type        = any
  default     = {}
}

variable "cert_manager_helm_config" {
  description = "Configuration for the cert-manager add-on."
  type        = any
  default     = {}
}
variable "external_dns_helm_config" {
  description = "Configuration for the External DNS add-on."
  type        = any
  default     = {}
}
variable "karpenter_helm_config" {
  description = "Configuration for the Karpenter add-on."
  type        = any
  default     = {}
}
variable "external_secrets_helm_config" {
  description = "Configuration for the External Secrets add-on."
  type        = any
  default     = {}
}
variable "metrics_server_helm_config" {
  description = "Configuration for the Metrics Server add-on."
  type        = any
  default     = {}
}
variable "keda_helm_config" {
  description = "Configuration for the Keda add-on."
  type        = any
  default     = {}
}
variable "istio_helm_config" {
  description = "Configuration for the Istio add-on."
  type        = any
  default     = {}
}
variable "aws_load_balancer_controller_helm_config" {
  description = "Configuration for the AWS Load Balancer Controller add-on."
  type        = any
  default     = {}
}

variable "velero_helm_config" {
  description = "Configuration for the Velero add-on."
  type        = any
  default     = {}
}

variable "observability_helm_config" {
  description = "Configuration for the Truemark Observability add-on."
  type        = any
  default     = {}
}

variable "castai_helm_config" {
  description = "Configuration for the Castai add-on."
  type        = any
  default     = {}
}

variable "auto_mode_helm_config" {
  description = "Configuration for the Castai add-on."
  type        = any
  default     = {}
}

variable "kube_bench_helm_config" {
  description = "Configuration for the kube-bench add-on."
  type        = map(any)
  default     = {}
}
