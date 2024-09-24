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

variable "create_cloudwatch_log_group" {
  description = "Create a CloudWatch log group for the EKS cluster"
  type        = bool
  default     = true
}

variable "enable_cluster_creator_admin_permissions" {
  description = "Indicates whether or not to add the cluster creator (the identity used by Terraform) as an administrator via access entry"
  type        = bool
  default     = false
}

###############################################
# EKS Addons Configuration
###############################################
variable "vpc_cni_before_compute" {
  description = "Whether to install the VPC CNI before the compute resources."
  type        = bool
  default     = false
}


###############################################
# Node Group Configuration
###############################################
variable "eks_managed_node_groups" {
  description = "Map of EKS managed node group definitions to create."
  type        = any
  default     = {}
}

variable "create_default_critical_addon_node_group" {
  description = "Create a default critical addon node group"
  type        = bool
  default     = true
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

variable "critical_addons_node_selector" {
  description = "Config for node selector for workloads"
  type        = map(any)
  default = {
    CriticalAddonsOnly = "true"
  }
}

variable "critical_addons_node_tolerations" {
  description = "Config for node tolerations for workloads"
  type        = list(any)
  default = [{
    key      = "CriticalAddonsOnly"
    operator = "Equal"
    effect   = "NoSchedule"
    value    = "true"
  }]
}

variable "truemark_arm_node_selector" {
  description = "Config for node selector for workloads"
  type        = map(any)
  default = {
    "karpenter.sh/nodepool" = "truemark-arm64"
  }
}

variable "truemark_arm_node_tolerations" {
  description = "Config for node tolerations for workloads"
  type        = list(any)
  default = [{
    key      = "karpenter.sh/nodepool"
    operator = "Equal"
    effect   = "NoSchedule"
    value    = "truemark-arm64"
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
# Load Balancer Controller Configuration
###############################################

variable "lbc_chart_version" {
  description = "The version of the Load Balancer Controller chart to install."
  type        = string
  default     = "1.8.1"
}

variable "lbc_image_tag" {
  description = "The image tag for the Load Balancer Controller."
  type        = string
  default     = null
  nullable    = true
}

###############################################
# Karpenter Configuration
###############################################
variable "enable_karpenter" {
  description = "Add karpenter to the cluster"
  type        = bool
  default     = true
}

variable "karpenter_version" {
  description = "Version of karpenter to install"
  type        = string
  default     = "0.37.0"
}

variable "karpenter_settings_featureGates_drift" {
  type        = bool
  description = "Enable or disable drift feature of karpenter"
  default     = true
}

variable "karpenter_node_template_default" {
  description = "Config for default node template for karpenter"
  type        = map(any)
  default = {
    subnetSelector = {
      network = "private"
    }
  }
}

variable "karpenter_node_pool_default_arm_requirements" {
  description = "Specifies the default requirements for the Karpenter ARM node pool template, including instance category, CPU, hypervisor, architecture, and capacity type."
  type        = map(any)
  default = {
    requirements = [
      {
        key      = "karpenter.k8s.aws/instance-category"
        operator = "In"
        values   = ["m", "c", "r"]
      },
      {
        key      = "karpenter.k8s.aws/instance-cpu"
        operator = "In"
        values   = ["4", "8", "16"]
      },
      {
        key      = "karpenter.k8s.aws/instance-hypervisor"
        operator = "In"
        values   = ["nitro"]
      },
      {
        key      = "kubernetes.io/arch"
        operator = "In"
        values   = ["arm64"]
      },
      {
        key      = "karpenter.sh/capacity-type"
        operator = "In"
        values   = ["on-demand"]
      }
    ]
  }
}

variable "karpenter_arm_node_pool_weight" {
  description = "The weight of the ARM node pool"
  type        = number
  default     = 10
  validation {
    condition     = var.karpenter_arm_node_pool_weight >= 0 && var.karpenter_arm_node_pool_weight <= 100
    error_message = "The weight of the node pool must be between 0 and 100."
  }
}

variable "karpenter_node_pool_default_amd_requirements" {
  description = "Specifies the default requirements for the Karpenter x86 node pool template, including instance category, CPU, hypervisor, architecture, and capacity type."
  type        = map(any)
  default = {
    requirements = [
      {
        key      = "karpenter.k8s.aws/instance-category"
        operator = "In"
        values   = ["m", "c", "r"]
      },
      {
        key      = "karpenter.k8s.aws/instance-cpu"
        operator = "In"
        values   = ["4", "8", "16"]
      },
      {
        key      = "karpenter.k8s.aws/instance-hypervisor"
        operator = "In"
        values   = ["nitro"]
      },
      {
        key      = "kubernetes.io/arch"
        operator = "In"
        values   = ["amd64"]
      },
      {
        key      = "karpenter.sh/capacity-type"
        operator = "In"
        values   = ["on-demand"]
      }
    ]
  }
}

variable "karpenter_amd_node_pool_weight" {
  description = "The weight of the AMD node pool"
  type        = number
  default     = 5
  validation {
    condition     = var.karpenter_amd_node_pool_weight >= 0 && var.karpenter_amd_node_pool_weight <= 100
    error_message = "The weight of the node pool must be between 0 and 100."
  }
}

variable "karpenter_nodepool_default_expireAfter" {
  default     = "720h"
  type        = string
  description = "The amount of time a Node can live on the cluster before being removed"
}

variable "truemark_nodeclass_default_ami_family" {
  description = "Specifies the default Amazon Machine Image (AMI) family to be used by the Karpenter provisioner."
  type        = string
  default     = "Bottlerocket"
}

variable "truemark_nodeclass_default_block_device_mappings" {
  description = "Specifies the default size and characteristics of the volumes used by the Karpenter provisioner. It defines the volume size, type, and encryption settings."
  type        = map(any)
  default = {
    specs = [
      {
        deviceName = "/dev/xvda"
        ebs = {
          volumeSize = "30Gi"
          volumeType = "gp3"
          encrypted  = true
        }
      },
      {
        deviceName = "/dev/xvdb"
        ebs = {
          volumeSize = "100Gi"
          volumeType = "gp3"
          encrypted  = true
        }
      }
    ]
  }
}

variable "karpenter_nodepool_default_ttl_after_empty" {
  description = "Sets the default Time to Live (TTL) for provisioned resources by the Karpenter default provisioner after they become empty or idle."
  type        = number
  default     = 300
}

variable "karpenter_nodepool_default_ttl_until_expired" {
  description = "Specifies the default Time to Live (TTL) for provisioned resources by the Karpenter default provisioner until they expire or are reclaimed."
  type        = number
  default     = 2592000
}



##

variable "environment" {}

variable "addons" {
  description = "Kubernetes addons"
  type        = any
  default = {
    enable_cert_manager                 = true
    enable_external_dns                 = false
    enable_external_secrets             = false
    enable_aws_load_balancer_controller = false
    enable_vpa                          = false
  }
}
variable "gitops_addons_org" {
  description = "Git repository org/user contains for addons"
  type        = string
  default     = "https://github.com/d3vb0ox"
}
variable "gitops_addons_repo" {
  description = "Git repository contains for addons"
  type        = string
  default     = "k8s-addons"
}
variable "gitops_addons_revision" {
  description = "Git repository revision/branch/ref for addons"
  type        = string
  default     = "main"
}
variable "gitops_addons_basepath" {
  description = "Git repository base path for addons"
  type        = string
  default     = ""
}
variable "gitops_addons_path" {
  description = "Git repository path for addons"
  type        = string
  default     = "addons"
}
