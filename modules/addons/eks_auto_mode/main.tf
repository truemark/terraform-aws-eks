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
  labels = var.addons_context.critical_addons_node_selector
  tags = merge(
    var.tags,
    {
      cluster_name = var.addons_context.cluster_name
      managedBy    = "terraform"
    }
  )
  partition                   = var.addons_context.aws_partition
  node_iam_role_name_prefix   = "${var.addons_context.cluster_name}-nodes-"
  node_iam_role_policy_prefix = "arn:${local.partition}:iam::aws:policy"
  vpc_id                      = var.addons_context.vpc_id
  cluster_security_group_id   = var.addons_context.cluster_security_group_id
  node_sg_name                = "${var.addons_context.cluster_name}-node"
  am_config                   = var.addons_context.auto_mode_system_nodes_config
  auto_mode_system_nodeclass_manifest = {
    apiVersion = "eks.amazonaws.com/v1"
    kind       = "NodeClass"
    metadata = {
      name = "${local.am_config.nodeclass_name}"
    }
    spec = {
      role = "${aws_iam_role.auto_mode_node.name}"
      ephemeralStorage = {
        size       = "100Gi"
        iops       = 3000
        throughput = 125
      }
      subnetSelectorTerms = [
        {
          tags = {
            network = "private"
          }
        }
      ]
      securityGroupSelectorTerms = [
        {
          tags = {
            "karpenter.sh/discovery" = "${var.addons_context.cluster_name}"
          }
        },
        {
          id = "${var.addons_context.node_security_group_id}"
        }
      ]
      tags = {
        Name                     = "${var.addons_context.cluster_name}-${local.am_config.nodeclass_name}"
        "karpenter.sh/discovery" = "${var.addons_context.cluster_name}"
      }
    }
  }

  auto_mode_system_nodepool_manifest = {
    apiVersion = "karpenter.sh/v1"
    kind       = "NodePool"
    metadata = {
      labels = {
        CriticalAddonsOnly = "true"
      }
      #local.labels
      name = "${local.am_config.nodepool_name}"
    }
    spec = {
      disruption = {
        budgets = [
          {
            nodes = "10%"
          }
        ]
        consolidateAfter    = "0s"
        consolidationPolicy = "WhenEmptyOrUnderutilized"
      }
      limits = "${local.am_config.nodepool_limits}"
      template = {
        spec = {
          expireAfter = "480h"
          nodeClassRef = {
            group = "eks.amazonaws.com"
            kind  = "NodeClass"
            name  = "${local.am_config.nodeclass_name}"
          }
          requirements = [
            {
              key      = "karpenter.sh/capacity-type"
              operator = "In"
              values   = toset(local.am_config.instance_capacity_type)
            },
            {
              key      = "eks.amazonaws.com/instance-category"
              operator = "In"
              values   = toset(local.am_config.instance_category)
            },
            {
              key      = "eks.amazonaws.com/instance-generation"
              operator = "Gt"
              values   = "${local.am_config.instance_generation}"
            },
            {
              key      = "kubernetes.io/arch"
              operator = "In"
              values   = toset(local.am_config.instance_arch)
            },
            {
              key      = "eks.amazonaws.com/instance-cpu"
              operator = "In"
              values   = toset(local.am_config.instance_cpu)
            },
            {
              key      = "eks.amazonaws.com/instance-hypervisor"
              operator = "In"
              values   = toset(local.am_config.instance_hypervisor)
            }
          ]
          terminationGracePeriod = local.am_config.instance_termination_grace_period
          taints = [
            {
              key    = "CriticalAddonsOnly"
              effect = "NoSchedule"
              value  = "true"
            }
          ]
        }
      }
    }
  }
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

resource "kubernetes_manifest" "auto_mode_node_class" {
  manifest = local.auto_mode_system_nodeclass_manifest
  depends_on = [
    aws_eks_access_entry.auto_mode_node
  ]
}

resource "kubernetes_manifest" "auto_mode_node_pool" {
  manifest = yamldecode(local.nodepool_yml)
  depends_on = [
    kubernetes_manifest.auto_mode_node_class
  ]
}
