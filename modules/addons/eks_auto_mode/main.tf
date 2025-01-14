################################################################################
# Auto_mode Configuration
###############################################################################

data "aws_iam_policy_document" "node_assume_role" {
  statement {
    sid     = "EKSAutoNodeAssumeRole"
    actions = ["sts:AssumeRole", "sts:TagSession", ]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

locals {
  labels                      = var.addons_context.critical_addons_node_selector
  partition                   = var.addons_context.aws_partition
  node_iam_role_name_prefix   = "${var.addons_context.cluster_name}-nodes-"
  node_iam_role_policy_prefix = "arn:${local.partition}:iam::aws:policy"
  vpc_id                      = var.addons_context.vpc_id
  cluster_security_group_id   = var.addons_context.cluster_security_group_id
  node_sg_name                = "${var.addons_context.cluster_name}-node"
  am_config                   = var.addons_context.auto_mode_system_nodes_config
  tags = merge(
    var.tags,
    {
      cluster_name = var.addons_context.cluster_name
      managedBy    = "terraform"
    }
  )
}

resource "aws_iam_role" "auto_mode_node" {
  name_prefix           = local.node_iam_role_name_prefix
  description           = "Truemark EKS Auto Mode Node IAM Role for ${var.addons_context.cluster_name}"
  assume_role_policy    = data.aws_iam_policy_document.node_assume_role.json
  force_detach_policies = true
  tags = {
    "kubernetes.io/cluster/${var.addons_context.cluster_name}" = "owned"
  }
}

resource "aws_iam_role_policy_attachment" "auto_mode_node" {
  for_each = { for k, v in merge(
    {
      AmazonEKS_CNI_Policy               = "${local.node_iam_role_policy_prefix}/AmazonEKS_CNI_Policy"
      AmazonEKSWorkerNodePolicy          = "${local.node_iam_role_policy_prefix}/AmazonEKSWorkerNodePolicy"
      AmazonEC2ContainerRegistryReadOnly = "${local.node_iam_role_policy_prefix}/AmazonEC2ContainerRegistryReadOnly"
  }, ) : k => v }
  policy_arn = each.value
  role       = aws_iam_role.auto_mode_node.name
}

resource "aws_eks_access_entry" "auto_mode_node" {
  cluster_name  = var.addons_context.cluster_name
  principal_arn = aws_iam_role.auto_mode_node.arn
  type          = "EC2"
}

resource "aws_eks_access_policy_association" "auto_mode_node" {
  cluster_name  = var.addons_context.cluster_name
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSAutoNodePolicy"
  principal_arn = aws_iam_role.auto_mode_node.arn
  depends_on    = [aws_eks_access_entry.auto_mode_node]
  access_scope {
    type = "cluster"
  }
}

###############################################################################
# Create nodepool for system components
###############################################################################

# resource "kubernetes_manifest" "auto_mode_node_class" {
#   manifest = local.auto_mode_system_nodeclass_manifest
#   depends_on = [
#     aws_eks_access_entry.auto_mode_node
#   ]
# }

# resource "kubernetes_manifest" "auto_mode_node_pool" {
#   manifest = yamldecode(local.nodepool_yml)
#   depends_on = [
#     kubernetes_manifest.auto_mode_node_class
#   ]
# }
