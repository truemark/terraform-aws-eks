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
  type        = list(map(string))
  default = [{
    key      = "CriticalAddonsOnly"
    operator = "Equal"
    effect   = "NoSchedule"
    value    = "true"
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
# CSI Snapshotter configuration
###############################################
variable "enable_snapshotter" {
  description = "Add external-snapshotter to the cluster"
  type        = bool
  default     = true
}

variable "enable_snapscheduler" {
  description = "Add snapscheduler to the cluster. Requires amd64 karpenter nodes"
  type        = bool
  default     = false
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

variable "karpenter_controller_version" {
  description = "Version of karpenter to install"
  type        = string
  default     = "0.37.0"
}

variable "karpenter_crds_version" {
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

###############################################
# External Secrets Configuration
###############################################
variable "external_secrets_ssm_parameter_arns" {
  description = "List of Systems Manager Parameter ARNs that contain secrets to mount using External Secrets"
  type        = list(string)
  default     = ["arn:aws:ssm:*:*:parameter/*"]
}

variable "external_secrets_secrets_manager_arns" {
  description = "List of Secrets Manager ARNs that contain secrets to mount using External Secrets"
  type        = list(string)
  default     = ["arn:aws:secretsmanager:*:*:secret:*"]
}

variable "external_secrets_kms_key_arns" {
  description = "List of KMS Key ARNs that are used by Secrets Manager that contain secrets to mount using External Secrets"
  type        = list(string)
  default     = ["arn:aws:kms:*:*:key/*"]
}


###############################################
# Monitoring Configuration
###############################################
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

variable "enable_monitoring" {
  description = "Enable monitoring"
  type        = bool
  default     = false
}

variable "alerts_sns_topics_arn" {
  description = "The ARN of the SNS topic to send alerts to"
  type        = string
  default     = null
}

variable "amp_alerting_rules_exclude_namespace" {
  description = "Namespaces to exclude from alerting"
  type        = string
  default     = ""
}

variable "prometheus_server_data_volume_size" {
  description = "Volume size for prometheus data"
  type        = string
  default     = "150Gi"
}

variable "amp_custom_alerting_rules" {
  description = "Prometheus K8s custom alerting rules"
  type        = string
  default     = ""
}

variable "prometheus_node_tolerations" {
  description = "K8S node tolerations for prometheus server"
  type        = list(any)
  default = [{
    key      = "CriticalAddonsOnly"
    operator = "Equal"
    effect   = "NoSchedule"
    value    = "true"
  }]
}

variable "prometheus_node_selector" {
  description = "K8S node selector for prometheus"
  type        = map(any)
  default = {
    CriticalAddonsOnly = "true"
  }
}

variable "truemark_arm_node_selector" {
  description = "K8S node selector for arm nodes"
  type        = map(any)
  default = {
    "karpenter.sh/nodepool" = "truemark-arm64"
  }
}

variable "truemark_arm_node_tolerations" {
  description = "K8S node tolerations for arm nodes"
  type        = list(any)
  default = [{
    key      = "karpenter.sh/nodepool"
    operator = "Equal"
    effect   = "NoSchedule"
    value    = "truemark-arm64"
  }]
}

variable "truemark_amd_node_selector" {
  description = "K8S node selector for amd nodes"
  type        = map(any)
  default = {
    "karpenter.sh/nodepool" = "truemark-amd64"
  }
}

variable "truemark_amd_node_tolerations" {
  description = "K8S node tolerations for amd nodes"
  type        = list(any)
  default = [{
    key      = "karpenter.sh/nodepool"
    operator = "Equal"
    effect   = "NoSchedule"
    value    = "truemark-amd64"
  }]
}

variable "prometheus_server_request_memory" {
  type        = string
  description = "Requested memory for prometheus instance"
  default     = "4Gi"
}

###############################################
# Ingress Configuration
###############################################

## Traefik
variable "enable_traefik" {
  type        = bool
  default     = false
  description = "Enables traefik deployment."
}

## Istio
variable "enable_istio" {
  type        = bool
  default     = false
  description = "Enables istio deployment"
}

variable "istio_release_version" {
  type        = string
  default     = "1.18.3"
  description = "The version of Istio to be installed."
}

variable "istio_mesh_id" {
  type        = string
  description = "The ID of the Istio mesh."
  default     = null
  nullable    = true
}

variable "istio_network" {
  type        = string
  description = "The network for the Istio mesh."
  default     = null
  nullable    = true
}

variable "istio_multi_cluster" {
  type        = bool
  description = "Enable multi-cluster support for Istio."
  default     = false
}

variable "istio_cluster_name" {
  type        = string
  description = "The name of the cluster."
  default     = null
  nullable    = true
}

variable "istio_nlb_tls_policy" {
  type        = string
  default     = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  description = "The TLS policy for the NLB."
}

variable "aws_managed_prefix_lists" {
  type        = map(string)
  description = "The AWS managed prefix lists."
  default = {
    cloudfront = "com.amazonaws.global.cloudfront.origin-facing"
  }
}

## External Gateway configs
variable "istio_enable_external_gateway" {
  type        = bool
  default     = true
  description = "Determines whether to enable an external gateway for Istio, allowing external traffic to reach Istio services."
}

variable "istio_external_gateway_lb_certs" {
  type        = list(string)
  description = "The certificates for the Istio external gateway load balancer."
  default     = []
}

variable "istio_external_gateway_service_kind" {
  type        = string
  default     = "NodePort"
  description = "The type of service for the Istio external gateway."
}

variable "istio_external_gateway_scaling_max_replicas" {
  type        = number
  description = "The maximum number of replicas for scaling the Istio external gateway."
  default     = 5
}

variable "istio_external_gateway_scaling_target_cpu_utilization" {
  type        = number
  description = "The target CPU utilization percentage for scaling the external gateway."
  default     = 80
}

variable "istio_external_gateway_enable_http_port" {
  description = "Enable http port"
  type        = bool
  default     = true
}

variable "istio_external_gateway_use_prefix_list" {
  description = "Use prefix list for security group rules"
  type        = bool
  default     = false
}

variable "istio_external_gateway_lb_source_ranges" {
  description = "List of CIDR blocks to allow traffic from"
  type        = list(string)
  default     = []
}

variable "istio_external_gateway_lb_proxy_protocol" {
  description = "Enable proxy protocol for the external gateway load balancer"
  type        = string
  default     = "*"
  nullable    = true
}

## Internal Gateway configs
variable "istio_enable_internal_gateway" {
  type        = bool
  default     = false
  description = "Controls the enabling of an internal gateway for Istio, which manages traffic within the Kubernetes cluster."
}

variable "istio_internal_gateway_lb_certs" {
  type        = list(string)
  description = "The certificates for the Istio internal gateway load balancer."
  default     = []
}

variable "istio_internal_gateway_service_kind" {
  type        = string
  default     = "NodePort"
  description = "The type of service for the Istio internal gateway."
}

variable "istio_internal_gateway_scaling_max_replicas" {
  type        = number
  description = "The maximum number of replicas for scaling the Istio internal gateway."
  default     = 5
}

variable "istio_internal_gateway_scaling_target_cpu_utilization" {
  type        = number
  description = "The target CPU utilization percentage for scaling the internal gateway."
  default     = 80
}

variable "istio_internal_gateway_enable_http_port" {
  description = "Enable http port"
  type        = bool
  default     = false
}

variable "istio_internal_gateway_lb_proxy_protocol" {
  description = "Enable proxy protocol for the external gateway load balancer"
  type        = string
  default     = "*"
  nullable    = true
}

variable "istio_internal_gateway_use_prefix_list" {
  description = "Use prefix list for security group rules"
  type        = bool
  default     = false
}

variable "istio_internal_gateway_lb_source_ranges" {
  description = "List of CIDR blocks to allow traffic from"
  type        = list(string)
  default     = []
}

###############################################
# Certmanager Configuration
###############################################
variable "enable_cert_manager" {
  type        = bool
  default     = false
  description = "Enables cert-manager deployment."
}

variable "cert_manager_chart_version" {
  description = "The version of the Helm chart to install."
  type        = string
  default     = "v1.15.3"
}

###############################################
# EKS Addons
###############################################
variable "vpa_enabled" {
  description = "Enable Vertical Pod Autoscaler"
  type        = bool
  default     = false
}

variable "goldilocks_enabled" {
  description = "Enable Goldilocks operator"
  type        = bool
  default     = false
}

###############################################
# Cast AI Configuration
###############################################
variable "cast_ai_agent_api_key" {
  description = "Cast AI agent API key"
  type        = string
  default     = ""
}

variable "enable_castai_spot_handler" {
  description = "Enable Cast AI spot handler"
  type        = bool
  default     = false
}

variable "enable_cast_ai_agent" {
  description = "Enable Cast AI agent"
  type        = bool
  default     = false
}

variable "enable_castai_cluster_controller" {
  description = "Enable Cast AI cluster controller"
  type        = bool
  default     = false
}

variable "enable_karpenter_controller_webhook" {
  description = "Enable or disable karpenter controller webhook"
  type        = bool
  default     = false
}

variable "enable_karpenter_crd_webhook" {
  description = "Enable or disable karpenter CRD webhook"
  type        = bool
  default     = false
}


####


variable "cert_manager_helm_config" {}
variable "external_dns_helm_config" {}
variable "karpenter_helm_config" {}
variable "external_secrets_helm_config" {}
variable "metrics_server_helm_config" {}
variable "keda_helm_config" {}
variable "istio_helm_config" {}
