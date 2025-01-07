################################################################################
# auto_mode Configuration
###############################################################################

## Variables

# Enable or disable auto_mode add-on
variable "enable_auto_mode" {
  description = "Flag to enable or disable the auto_mode controller add-on."
  type        = bool
  default     = false
}

variable "auto_mode_additional_policies" {
  description = "Flag to enable or disable the auto_mode controller add-on."
  type        = map(string)
  default     = {}
}

data "aws_partition" "current" {}
data "aws_caller_identity" "current" {}

################################################################################
# Node IAM Role
# This is used by the nodes launched by Karpenter
################################################################################

locals {
  partition                   = data.aws_partition.current.partition
  node_iam_role_name          = "eks-auto-mode-${var.cluster_name}"
  node_iam_role_policy_prefix = "arn:${local.partition}:iam::aws:policy"

  # ipv4_cni_policy = { for k, v in {
  #   AmazonEKS_CNI_Policy = "${local.node_iam_role_policy_prefix}/AmazonEKS_CNI_Policy"
  # } : k => v if var.node_iam_role_attach_cni_policy && var.cluster_ip_family == "ipv4" }
  # ipv6_cni_policy = { for k, v in {
  #   AmazonEKS_CNI_IPv6_Policy = "arn:${local..partition}:iam::${data.aws_caller_identity.current.account_id}:policy/AmazonEKS_CNI_IPv6_Policy"
  # } : k => v if var.node_iam_role_attach_cni_policy && var.cluster_ip_family == "ipv6" }
}

data "aws_iam_policy_document" "node_assume_role" {
  count = var.enable_auto_mode ? 1 : 0

  statement {
    sid     = "EKSNodeAssumeRole"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "auto_mode_node" {
  count = var.enable_auto_mode ? 1 : 0

  name        = local.node_iam_role_name
  description = "Truemark EKS Auto Mode Node IAM Role for ${var.cluster_name}"

  assume_role_policy    = data.aws_iam_policy_document.node_assume_role[0].json
  force_detach_policies = true
}

# Policies attached ref https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_node_group
resource "aws_iam_role_policy_attachment" "auto_mode_node" {
  for_each = { for k, v in merge(
    {
      AmazonEKS_CNI_Policy               = "${local.node_iam_role_policy_prefix}/AmazonEKS_CNI_Policy"
      AmazonEKSWorkerNodePolicy          = "${local.node_iam_role_policy_prefix}/AmazonEKSWorkerNodePolicy"
      AmazonEC2ContainerRegistryReadOnly = "${local.node_iam_role_policy_prefix}/AmazonEC2ContainerRegistryReadOnly"
    },
    # local.ipv4_cni_policy,
    # local.ipv6_cni_policy
  ) : k => v if var.enable_auto_mode }

  policy_arn = each.value
  role       = aws_iam_role.auto_mode_node[0].name
}

resource "aws_iam_role_policy_attachment" "auto_mode_additional_policies" {
  for_each   = { for k, v in var.auto_mode_additional_policies : k => v if var.enable_auto_mode }
  policy_arn = each.value
  role       = aws_iam_role.auto_mode_node[0].name
}

################################################################################
# Access Entry
################################################################################

resource "aws_eks_access_entry" "auto_mode_node" {
  # count = var.create && var.create_access_entry ? 1 : 0

  cluster_name  = var.cluster_name
  principal_arn = aws_iam_role.auto_mode_node[0].arn
  type          = "EC2_LINUX"
  # depends_on = [
  #   # If we try to add this too quickly, it fails. So .... we wait
  #   aws_sqs_queue_policy.this,
  # ]
}
