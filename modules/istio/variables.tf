variable "vpc_id" {
  type        = string
  description = "The ID of the VPC."
}

variable "istio_release_version" {
  type        = string
  default     = "1.18.3"
  description = "The version of Istio to be installed."
}

variable "istio_release_namespace" {
  type        = string
  default     = "istio-system"
  description = "The Kubernetes namespace where Istio will be installed."
}

variable "istio_enable_external_gateway" {
  type        = bool
  default     = true
  description = "Determines whether to enable an external gateway for Istio, allowing external traffic to reach Istio services."
}

variable "istio_enable_internal_gateway" {
  type        = bool
  default     = false
  description = "Controls the enabling of an internal gateway for Istio, which manages traffic within the Kubernetes cluster."
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

## External Gateway configs
variable "istio_external_gateway_lb_certs" {
  type        = list(string)
  description = "The certificates for the Istio external gateway load balancer."
  default     = []
}

variable "istio_external_gateway_service_kind" {
  type        = string
  default     = "NodePort"
  description = "The type of service for the Istio external gateway."
  validation {
    condition     = contains(["NodePort", "LoadBalancer", "ClusterIP"], var.istio_external_gateway_service_kind)
    error_message = "istio_external_gateway_service_kind must be one of NodePort, LoadBalancer, or ClusterIP."
  }
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
variable "istio_internal_gateway_lb_certs" {
  type        = list(string)
  description = "The certificates for the Istio internal gateway load balancer."
  default     = []
}

variable "istio_internal_gateway_service_kind" {
  type        = string
  default     = "NodePort"
  description = "The type of service for the Istio internal gateway."
  validation {
    condition     = contains(["NodePort", "LoadBalancer", "ClusterIP"], var.istio_internal_gateway_service_kind)
    error_message = "istio_internal_gateway_service_kind must be one of NodePort, LoadBalancer, or ClusterIP."
  }
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
  default     = true
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

variable "istio_internal_gateway_lb_proxy_protocol" {
  description = "Enable proxy protocol for the external gateway load balancer"
  type        = string
  default     = "*"
  nullable    = true
}
