################################################################################
# Auto_mode Configuration
###############################################################################

# variable "auto_mode" {
#   description = "Configuration for the auto_mode controller add-on."
#   type = object({
#     truemark_nodeclass_default = object({
#       block_device_mappings = list(object({
#         deviceName = string
#         ebs = object({
#           volumeSize = string
#           volumeType = string
#           encrypted  = bool
#         })
#       }))
#       subnetSelector = map(string)
#     })
#   })
#   default = {
#     truemark_nodeclass_default = {
#       block_device_mappings = []
#       subnetSelector        = {}
#     }
#   }
# }

data "aws_partition" "current" {}

data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "node_assume_role" {
  count = var.enable_auto_mode ? 1 : 0
  statement {
    sid     = "EKSAutoNodeAssumeRole"
    actions = ["sts:AssumeRole", "sts:TagSession", ]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

################################################################################
# Node IAM Role
# This is used by the nodes launched by Karpenter
################################################################################

locals {
  partition                     = data.aws_partition.current.partition
  node_iam_role_name            = "eks-${var.cluster_name}-node-role"
  node_iam_role_policy_prefix   = "arn:${local.partition}:iam::aws:policy"
  vpc_id                        = var.vpc_id
  cluster_security_group_id     = var.cluster_security_group_id
  node_sg_name                  = "${var.cluster_name}-node"
  create_node_sg                = var.enable_auto_mode
  auto_mode_additional_policies = {}

  ################################################################################
  # Node Security Group
  # Defaults follow https://docs.aws.amazon.com/eks/latest/userguide/sec-group-reqs.html
  # Plus NTP/HTTPS (otherwise nodes fail to launch)
  ################################################################################

  node_security_group_rules = {
    ingress_cluster_443 = {
      description                   = "Cluster API to node groups"
      protocol                      = "tcp"
      from_port                     = 443
      to_port                       = 443
      type                          = "ingress"
      source_cluster_security_group = true
    }
    ingress_cluster_kubelet = {
      description                   = "Cluster API to node kubelets"
      protocol                      = "tcp"
      from_port                     = 10250
      to_port                       = 10250
      type                          = "ingress"
      source_cluster_security_group = true
    }
    ingress_self_coredns_tcp = {
      description = "Node to node CoreDNS"
      protocol    = "tcp"
      from_port   = 53
      to_port     = 53
      type        = "ingress"
      self        = true
    }
    ingress_self_coredns_udp = {
      description = "Node to node CoreDNS UDP"
      protocol    = "udp"
      from_port   = 53
      to_port     = 53
      type        = "ingress"
      self        = true
    }
  }

  node_security_group_recommended_rules = { for k, v in {
    ingress_nodes_ephemeral = {
      description = "Node to node ingress on ephemeral ports"
      protocol    = "tcp"
      from_port   = 1025
      to_port     = 65535
      type        = "ingress"
      self        = true
    }
    # metrics-server
    ingress_cluster_4443_webhook = {
      description                   = "Cluster API to node 4443/tcp webhook"
      protocol                      = "tcp"
      from_port                     = 4443
      to_port                       = 4443
      type                          = "ingress"
      source_cluster_security_group = true
    }
    # prometheus-adapter
    ingress_cluster_6443_webhook = {
      description                   = "Cluster API to node 6443/tcp webhook"
      protocol                      = "tcp"
      from_port                     = 6443
      to_port                       = 6443
      type                          = "ingress"
      source_cluster_security_group = true
    }
    # Karpenter
    ingress_cluster_8443_webhook = {
      description                   = "Cluster API to node 8443/tcp webhook"
      protocol                      = "tcp"
      from_port                     = 8443
      to_port                       = 8443
      type                          = "ingress"
      source_cluster_security_group = true
    }
    # ALB controller, NGINX
    ingress_cluster_9443_webhook = {
      description                   = "Cluster API to node 9443/tcp webhook"
      protocol                      = "tcp"
      from_port                     = 9443
      to_port                       = 9443
      type                          = "ingress"
      source_cluster_security_group = true
    }
    # ingress_all = {
    #   description = "Allow all ingress"
    #   protocol    = "-1"
    #   from_port   = 0
    #   to_port     = 0
    #   type        = "ingress"
    #   cidr_blocks = ["0.0.0.0/0"]
    # }
    egress_all = {
      description = "Allow all egress"
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      type        = "egress"
      cidr_blocks = ["0.0.0.0/0"]
  } } : k => v }
}

resource "aws_iam_role" "auto_mode_node" {
  count                 = var.enable_auto_mode ? 1 : 0
  name                  = local.node_iam_role_name
  description           = "Truemark EKS Auto Mode Node IAM Role for ${var.cluster_name}"
  assume_role_policy    = data.aws_iam_policy_document.node_assume_role[0].json
  force_detach_policies = true
  tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "owned"
  }
}

resource "aws_iam_role_policy_attachment" "auto_mode_node" {
  for_each = { for k, v in merge(
    {
      AmazonEKS_CNI_Policy               = "${local.node_iam_role_policy_prefix}/AmazonEKS_CNI_Policy"
      AmazonEKSWorkerNodePolicy          = "${local.node_iam_role_policy_prefix}/AmazonEKSWorkerNodePolicy"
      AmazonEC2ContainerRegistryReadOnly = "${local.node_iam_role_policy_prefix}/AmazonEC2ContainerRegistryReadOnly"
      # AmazonSSMManagedInstanceCore       = "${local.node_iam_role_policy_prefix}/AmazonSSMManagedInstanceCore"
  }, ) : k => v if var.enable_auto_mode }
  policy_arn = each.value
  role       = aws_iam_role.auto_mode_node[0].name
}

resource "aws_iam_role_policy_attachment" "auto_mode_additional_policies" {
  for_each   = { for k, v in local.auto_mode_additional_policies : k => v if var.enable_auto_mode }
  policy_arn = each.value
  role       = aws_iam_role.auto_mode_node[0].name
}

resource "aws_eks_access_entry" "auto_mode_node" {
  count         = var.enable_auto_mode ? 1 : 0
  cluster_name  = var.cluster_name
  principal_arn = aws_iam_role.auto_mode_node[0].arn
  type          = "EC2"
}

resource "aws_eks_access_policy_association" "auto_mode_node" {
  count         = var.enable_auto_mode ? 1 : 0
  cluster_name  = var.cluster_name
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSAutoNodePolicy"
  principal_arn = aws_iam_role.auto_mode_node[0].arn
  depends_on    = [aws_eks_access_entry.auto_mode_node]
  access_scope {
    type = "cluster"
  }
}

resource "aws_security_group" "node" {
  count = var.enable_auto_mode ? 1 : 0
  # name  = local.node_sg_name
  name_prefix = "${local.node_sg_name}-"
  description = "EKS automode node security group for ${var.cluster_name}"
  vpc_id      = local.vpc_id
  tags = merge(
    var.tags,
    {
      "Name"                                      = local.node_sg_name
      "karpenter.sh/discovery"                    = var.cluster_name
      "kubernetes.io/cluster/${var.cluster_name}" = "owned"
    },
  )
  lifecycle {
    create_before_destroy = true
  }
}

# Allow traffic from Nodes to Cluster
resource "aws_security_group_rule" "node_to_cluster" {
  count                    = var.enable_auto_mode ? 1 : 0
  description              = "Allow traffic from node group to cluster security group"
  security_group_id        = local.cluster_security_group_id
  source_security_group_id = aws_security_group.node[0].id
  type                     = "ingress"
  protocol                 = "-1"
  from_port                = 0
  to_port                  = 0
}

resource "aws_security_group_rule" "node" {
  for_each = { for k, v in merge(
    local.node_security_group_rules,
    local.node_security_group_recommended_rules,
  ) : k => v if local.create_node_sg }
  security_group_id        = aws_security_group.node[0].id
  protocol                 = each.value.protocol
  from_port                = each.value.from_port
  to_port                  = each.value.to_port
  type                     = each.value.type
  description              = lookup(each.value, "description", null)
  cidr_blocks              = lookup(each.value, "cidr_blocks", null)
  ipv6_cidr_blocks         = lookup(each.value, "ipv6_cidr_blocks", null)
  prefix_list_ids          = lookup(each.value, "prefix_list_ids", [])
  self                     = lookup(each.value, "self", null)
  source_security_group_id = try(each.value.source_cluster_security_group, false) ? local.cluster_security_group_id : lookup(each.value, "source_security_group_id", null)
}

################################################################################
## Create nodepool for system components
################################################################################

resource "kubernetes_manifest" "auto_mode_node_class" {
  count = var.enable_auto_mode ? 1 : 0
  depends_on = [
    aws_security_group.node[0],
    aws_security_group_rule.node_to_cluster,
    aws_eks_access_entry.auto_mode_node[0]
  ]
  manifest = {
    apiVersion = "eks.amazonaws.com/v1"
    kind       = "NodeClass"
    metadata = {
      name = "truemark-system"
    }
    spec = {
      role = "${aws_iam_role.auto_mode_node[0].name}"
      ephemeralStorage = {
        size       = "80Gi"
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
            "karpenter.sh/discovery" = var.cluster_name
          }
        }
      ]
      tags = {
        Name                     = "${var.cluster_name}-truemark-system"
        "karpenter.sh/discovery" = var.cluster_name
      }
    }
  }
}

resource "kubernetes_manifest" "auto_mode_node_pool" {
  count = var.enable_auto_mode ? 1 : 0
  manifest = {
    apiVersion = "karpenter.sh/v1"
    kind       = "NodePool"
    metadata = {
      labels = {
        CriticalAddonsOnly = "true"
      }
      name = "truemark-system"
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
      limits = {}
      template = {
        spec = {
          expireAfter = "480h"
          nodeClassRef = {
            group = "eks.amazonaws.com"
            kind  = "NodeClass"
            name  = "truemark-system"
          }
          requirements = [
            {
              key      = "karpenter.sh/capacity-type"
              operator = "In"
              values   = ["on-demand"]
            },
            {
              key      = "eks.amazonaws.com/instance-category"
              operator = "In"
              values   = ["c", "m", "r"]
            },
            {
              key      = "eks.amazonaws.com/instance-generation"
              operator = "Gt"
              values   = ["4"]
            },
            {
              key      = "kubernetes.io/arch"
              operator = "In"
              values   = ["amd64"]
            },
            {
              key      = "eks.amazonaws.com/instance-cpu"
              operator = "In"
              values   = ["2", "4"]
            },
            {
              key      = "eks.amazonaws.com/instance-hypervisor"
              operator = "In"
              values   = ["nitro"]
            }
          ]
          terminationGracePeriod = "24h0m0s"
          taints = [
            {
              effect = "NoSchedule"
              key    = "CriticalAddonsOnly"
            }
          ]
        }
      }
    }
  }
  depends_on = [
    kubernetes_manifest.auto_mode_node_class
  ]
}
