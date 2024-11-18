################################################################################
# AWS EBS CSI Resources
################################################################################
variable "enable_aws_ebs_csi_resources" {
  description = "Enable enable_aws_ebs_csi_resources add-on"
  type        = bool
  default     = false
}

variable "aws_ebs_csi_resources" {
  description = "ebs-csi-resources add-on configuration values"
  type        = any
  default     = {}
}

locals {
  aws_ebs_csi_resources_namespace = try(var.aws_ebs_csi_resources.namespace, "kube-system")
}

# TODO: figure out the terraform way of creating local chart path
module "aws_ebs_csi_resources" {
  source  = "aws-ia/eks-blueprints-addon/aws"
  version = "1.1.1"

  create = var.enable_aws_ebs_csi_resources

  # Disable helm release
  create_release = var.create_kubernetes_resources

  # https://github.com/aws/eks-charts/blob/master/stable/aws-load-balancer-controller/Chart.yaml
  name        = try(var.aws_ebs_csi_resources.name, "aws-ebs-csi-resources")
  description = try(var.aws_ebs_csi_resources.description, "A Helm chart to deploy aws-ebs-csi-resources")
  namespace   = local.aws_ebs_csi_resources_namespace
  # namespace creation is false here as kube-system already exists by default
  create_namespace = try(var.aws_ebs_csi_resources.create_namespace, false)
  chart            = try(var.aws_ebs_csi_resources.chart, "${path.root}/bootstrap/aws-ebs-csi-resources")
  tags = var.tags
}
