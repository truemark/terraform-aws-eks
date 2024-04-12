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

variable "eks_managed_node_groups" {
  description = "Map of EKS managed node group definitions to create."
  type        = any
  default     = {}
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

variable "sso_roles" {
  description = "AWS SSO roles that will be mapped to RBAC roles."
  type = list(object({
    role_name = string,
    groups    = list(string),
  }))
  default = []
}

variable "iam_roles" {
  description = "AWS IAM roles that will be mapped to RBAC roles."
  type        = list(any)
  default     = []
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
  default     = "1.26"
}

variable "enable_karpenter" {
  description = "Add karpenter to the cluster"
  type        = bool
  default     = true
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

variable "karpenter_provisioner_default_requirements" {
  description = "Specifies the default requirements for the Karpenter provisioner template, including instance category, CPU, hypervisor, architecture, and capacity type."
  type        = map(any)
  default = {
    requirements = [
      {
        key      = "karpenter.k8s.aws/instance-category"
        operator = "In"
        values   = ["m"]
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

variable "karpenter_nodepool_default_expireAfter" {
  default     = "720h"
  type        = string
  description = "The amount of time a Node can live on the cluster before being removed"
}

variable "karpenter_provisioner_default_ami_family" {
  description = "Specifies the default Amazon Machine Image (AMI) family to be used by the Karpenter provisioner."
  type        = string
  default     = "Bottlerocket"
}

variable "karpenter_provisioner_default_block_device_mappings" {
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

variable "karpenter_provisioner_default_cpu_limits" {
  description = "Defines the default CPU limits for the Karpenter default provisioner, ensuring resource allocation and utilization."
  type        = number
  default     = 300
}

variable "karpenter_provisioner_default_ttl_after_empty" {
  description = "Sets the default Time to Live (TTL) for provisioned resources by the Karpenter default provisioner after they become empty or idle."
  type        = number
  default     = 300
}

variable "karpenter_provisioner_default_ttl_until_expired" {
  description = "Specifies the default Time to Live (TTL) for provisioned resources by the Karpenter default provisioner until they expire or are reclaimed."
  type        = number
  default     = 2592000
}

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

## Variables ingress controllers
variable "enable_traefik" {
  type        = bool
  default     = false
  description = "Enables traefik deployment."
}

variable "enable_istio" {
  type        = bool
  default     = false
  description = "Enables istio deployment"
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

variable "enable_cert_manager" {
  type        = bool
  default     = false
  description = "Enables cert-manager deployment."
}

variable "amp_custom_alerting_rules" {
  description = "Prometheus K8s custom alerting rules"
  type        = string
  default     = ""
}
