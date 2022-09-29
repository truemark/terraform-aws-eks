variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = ""
}

variable "subnets_ids" {
  description = "A list of subnet IDs where the nodes/node groups will be provisioned."
  type        = list(string)
  default     = []
}

variable "vpc_id" {
  description = "ID of the VPC where the cluster and its nodes will be provisioned"
  type        = string
  default     = null
}

variable "eks_managed_node_groups" {
  description = "Map of EKS managed node group definitions to create"
  type        = any
  default     = {}
}

variable "eks_managed_node_group_defaults" {
  description = "Map of EKS managed node group default configurations"
  type        = any
  default     = {}
}

variable "access_points_security_group_ids" {
  description = "The security groups ids of access points to kubernetes API"
  type        = list(string)
  default     = []
}

variable "sso_roles" {
  description = ""
  type = list(object({
    role_name = string,
    groups    = list(string),
  }))
  default = []
}

variable "public_alb" {

}

variable "private_alb" {

}

variable "private_subnets" {

}

variable "public_subnets" {

}
