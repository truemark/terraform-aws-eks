################################################################################
# AWS EBS CSI Resources Configuration
################################################################################

## Variables

# Enable or disable AWS EBS CSI Resources add-on
variable "enable_aws_ebs_csi_resources" {
  description = "Flag to enable or disable the AWS EBS CSI resources add-on."
  type        = bool
  default     = false
}

# Configuration for AWS EBS CSI Resources Helm chart
variable "aws_ebs_csi_resources" {
  description = <<-EOT
    Configuration for the AWS EBS CSI Resources add-on.
    Allows customization of various aspects such as chart version, namespace, role creation,
    and additional Helm values or settings.
  EOT
  type = object({
    name             = optional(string, "aws-ebs-csi-resources") # Helm release name
    description      = optional(string, "A Helm chart to deploy aws-ebs-csi-resources")
    namespace        = optional(string, "kube-system")
    create_namespace = optional(bool, false)
    chart            = optional(string, "bootstrap/aws-ebs-csi-resources")
    chart_version    = optional(string, null)
    repository       = optional(string, null)
    values           = optional(list(any), [])
    set = optional(list(object({
      name  = string
      value = string
    })), [])
  })
  default = {}
}

## Locals

# Local variable for the namespace where AWS EBS CSI resources will be deployed
locals {
  aws_ebs_csi_resources_namespace = try(var.aws_ebs_csi_resources.namespace, "kube-system")
}

################################################################################
# Helm Release for AWS EBS CSI Resources
################################################################################
# TODO: @piyush - Terraform release do not work for this module
module "aws_ebs_csi_resources" {
  source  = "aws-ia/eks-blueprints-addon/aws"
  version = "1.1.1"

  # Enable or disable the creation of this module
  create = var.enable_aws_ebs_csi_resources

  # Flag to disable the Helm release (useful when deploying via GitOps)
  create_release = var.create_kubernetes_resources

  # Helm chart configuration
  name             = try(var.aws_ebs_csi_resources.name, "aws-ebs-csi-resources")
  description      = try(var.aws_ebs_csi_resources.description, "A Helm chart to deploy aws-ebs-csi-resources")
  namespace        = local.aws_ebs_csi_resources_namespace
  create_namespace = try(var.aws_ebs_csi_resources.create_namespace, false) # "kube-system" exists by default
  chart            = try(var.aws_ebs_csi_resources.chart, "${path.root}/bootstrap/aws-ebs-csi-resources")
  chart_version    = try(var.aws_ebs_csi_resources.chart_version, null) # Use null if version is unspecified
  repository       = try(var.aws_ebs_csi_resources.repository, null)    # Use null if no repository is provided

  # Tags for resources
  tags = var.tags

  # Custom Helm values
  values = try(var.aws_ebs_csi_resources.values, [])

  # Additional Helm settings
  set = try(var.aws_ebs_csi_resources.set, [])
}
