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
# EKS Addons Configuration
###############################################

# Configuration for the Cert-Manager Helm chart.
# Used for managing TLS certificates within the Kubernetes cluster.
variable "cert_manager_helm_config" {
  description = "Configuration settings for the Cert-Manager Helm chart deployment."
  type        = map(any)
  default     = {}
}

# Configuration for the External DNS Helm chart.
# Used for dynamically managing DNS records from Kubernetes resources.
variable "external_dns_helm_config" {
  description = "Configuration settings for the External DNS Helm chart deployment."
  type        = map(any)
  default     = {}
}

# Configuration for the Karpenter Helm chart.
# An open-source Kubernetes cluster autoscaler.
variable "karpenter_helm_config" {
  description = "Configuration settings for the Karpenter Helm chart deployment."
  type        = map(any)
  default     = {}
}

# Configuration for the External Secrets Helm chart.
# Used for integrating external secret stores (e.g., AWS Secrets Manager, HashiCorp Vault) with Kubernetes.
variable "external_secrets_helm_config" {
  description = "Configuration settings for the External Secrets Helm chart deployment."
  type        = map(any)
  default     = {}
}

# Configuration for the Metrics Server Helm chart.
# Used for aggregating resource usage data for Kubernetes components.
variable "metrics_server_helm_config" {
  description = "Configuration settings for the Metrics Server Helm chart deployment."
  type        = map(any)
  default     = {}
}

# Configuration for the KEDA Helm chart.
# Kubernetes-based Event Driven Autoscaler (KEDA) for event-driven scaling.
variable "keda_helm_config" {
  description = "Configuration settings for the KEDA Helm chart deployment."
  type        = map(any)
  default     = {}
}

# Configuration for the Istio Helm chart.
# Used for deploying Istio, a service mesh for managing traffic between microservices.
variable "istio_helm_config" {
  description = "Configuration settings for the Istio Helm chart deployment."
  type        = map(any)
  default     = {}
}

# Configuration for the AWS Load Balancer Controller Helm chart.
# Used for managing Elastic Load Balancers for Kubernetes services.
variable "aws_load_balancer_controller_helm_config" {
  description = "Configuration settings for the AWS Load Balancer Controller Helm chart deployment."
  type        = map(any)
  default     = {}
}
