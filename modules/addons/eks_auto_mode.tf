################################################################################
# auto_mode Configuration
################################################################################

## Variables

# Enable or disable auto_mode add-on
variable "enable_auto_mode" {
  description = "Flag to enable or disable the auto_mode controller add-on."
  type        = bool
  default     = false
}

# # Configuration for auto_mode Helm chart
variable "auto_mode" {
  description = <<-EOT
    Configuration for the auto_mode cluster resources
    Supports customization of namespace, IAM roles, Helm chart values, CRD configurations,
    and node pools for arm64 and amd64 architectures.
  EOT
  type = object({
    name             = optional(string, "auto_mode")
    description      = optional(string, "A Helm chart to deploy auto_mode")
    namespace        = optional(string, "kube-system")
    create_namespace = optional(bool, true)
    chart            = optional(string, "auto_mode")
    chart_version    = optional(string, "1.0.7")
    # repository       = optional(string, "oci://public.ecr.aws/karpenter")
    values = optional(list(string), [])
    set = optional(list(object({
      name  = string
      value = string
    })), [])
    set_sensitive = optional(list(object({
      name  = string
      value = string
    })), [])
    timeout = optional(string, null)
    verify  = optional(bool, null)
    # enable_pod_identity               = optional(bool, true)
    # create_pod_identity_association   = optional(bool, true)
    # enable_v1_permissions             = optional(bool, true)
    # enable_irsa                       = optional(bool, false)
    node_iam_role_additional_policies = optional(map(string), {
      AmazonEKSWorkerNodeMinimalPolicy   = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodeMinimalPolicy",
      AmazonEC2ContainerRegistryPullOnly = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPullOnly",
    })
    truemark_nodeclass_default = optional(object({
      ami_family = optional(string, "bottlerocket")
      block_device_mappings = optional(list(object({
        deviceName = string
        ebs = object({
          volumeSize = string
          volumeType = string
          encrypted  = bool
        })
      })), [])
      subnetSelector        = optional(map(string), { network = "private" })
      securityGroupSelector = optional(map(string), {})
    }), {})
    truemark_node_pool_default = optional(object({
      arm64 = optional(object({
        requirements         = optional(list(object({ key = string, operator = string, values = list(string) })), [])
        consolidation_policy = optional(string, "WhenUnderutilized")
        expire_after         = optional(string, "720h")
        node_pool_weight     = optional(number, 10)
      }), {})
      amd64 = optional(object({
        requirements         = optional(list(object({ key = string, operator = string, values = list(string) })), [])
        consolidation_policy = optional(string, "WhenUnderutilized")
        expire_after         = optional(string, "720h")
        node_pool_weight     = optional(number, 10)
      }), {})
    }), {})
  })
  default = {}
}

## Locals

# Dynamic values for namespace, service account, and webhook configurations
locals {
  auto_mode_service_account = try(var.karpenter.service_account_name, "karpenter")
  auto_mode_node_pools = {
    arm64 = {
      name                = "truemark-arm64"
      architecture        = "arm64"
      requirements        = try(var.auto_mode.truemark_node_pool_default.arm64.requirements, [])
      consolidationPolicy = try(var.auto_mode.truemark_node_pool_default.arm64.consolidation_policy, "WhenUnderutilized")
      expireAfter         = try(var.auto_mode.truemark_node_pool_default.arm64.expire_after, "720h")
      weight              = try(var.auto_mode.truemark_node_pool_default.arm64.node_pool_weight, 10)
      requirements = try(var.auto_mode.truemark_node_pool_default.arm64.requirements, [
        {
          key      = "eks.amazonaws.com/instance-category"
          operator = "In"
          values   = ["m", "c", "r"]
        },
        {
          key      = "eks.amazonaws.com/instance-cpu"
          operator = "In"
          values   = ["4", "8", "16"]
        },
        {
          key      = "eks.amazonaws.com/instance-hypervisor"
          operator = "In"
          values   = ["nitro"]
        },
        {
          key      = "kubernetes.io/arch"
          operator = "In"
          values   = ["arm64"]
        },
        {
          key      = "karpenter.sh/capacity-type"
          operator = "In"
          values   = ["on-demand"]
        }
      ])
    }
    amd64 = {
      name                = "truemark-amd64"
      architecture        = "amd64"
      requirements        = try(var.auto_mode.truemark_node_pool_default.amd64.requirements, [])
      consolidationPolicy = try(var.auto_mode.truemark_node_pool_default.amd64.consolidation_policy, "WhenUnderutilized")
      expireAfter         = try(var.auto_mode.truemark_node_pool_default.amd64.expire_after, "720h")
      weight              = try(var.auto_mode.truemark_node_pool_default.amd64.node_pool_weight, 10)
      requirements = try(var.auto_mode.truemark_node_pool_default.amd64.requirements, [
        {
          key      = "eks.amazonaws.com/instance-category"
          operator = "In"
          values   = ["m", "c", "r"]
        },
        {
          key      = "eks.amazonaws.com/instance-cpu"
          operator = "In"
          values   = ["4", "8", "16"]
        },
        {
          key      = "eks.amazonaws.com/instance-hypervisor"
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
      ])
    }
  }
}

# Modules and Resources

module "auto_mode_helm" {
  source  = "aws-ia/eks-blueprints-addon/aws"
  version = "1.1.1"

  create = var.enable_auto_mode

  # Disable helm release
  create_release   = var.create_kubernetes_resources
  name             = try(var.auto_mode.name, "auto_mode")
  description      = try(var.auto_mode.description, "A Helm chart to deploy auto_mode")
  namespace        = try(var.auto_mode.namespace, "auto_mode")
  create_namespace = try(var.auto_mode.create_namespace, true)
  chart            = try(var.auto_mode.chart, "auto_mode")
  chart_version    = try(var.auto_mode.chart_version, "1.0.7")
  repository       = try(var.auto_mode.repository, "oci://public.ecr.aws/auto_mode")
  values = concat(try(var.auto_mode.values, []), var.auto_mode.use_system_critical_nodegroup ? [
    jsonencode({
      tolerations  = var.critical_addons_node_tolerations
      nodeSelector = var.critical_addons_node_selector
    })
    ] : []
  )
  timeout = try(var.auto_mode.timeout, null)
  verify  = try(var.auto_mode.verify, null)
  set = concat(
    [
      {
        name  = "settings.clusterName"
        value = var.cluster_name
      },
      {
        name  = "settings.clusterEndpoint"
        value = var.cluster_endpoint
      },
      {
        name  = "settings.interruptionQueue"
        value = try(module.auto_mode[0].queue_name, null)
      },
      {
        name  = "serviceAccount.name"
        value = "karpenter"
      },
      {
        name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
        value = try(module.auto_mode[0].iam_role_arn, null)
      }
    ],
    try(var.auto_mode.set, [])
  )
  set_sensitive = try(var.auto_mode.set_sensitive, [])

  tags = var.tags
}

## Create default truemark nodepool
resource "kubernetes_manifest" "auto_mode_node_class" {
  count = var.enable_auto_mode && var.create_kubernetes_resources ? 1 : 0

  manifest = {
    apiVersion = "eks.amazonaws.com/v1"
    kind       = "NodeClass"
    metadata = {
      name = "truemark"
    }
    spec = {
      amiFamily = try(var.auto_mode.truemark_nodeclass_default.ami_family, "bottlerocket")
      blockDeviceMappings = try(var.auto_mode.truemark_nodeclass_default.block_device_mappings, [
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
      ])
      role = module.auto_mode[0].node_iam_role_name
      subnetSelectorTerms = [
        {
          tags = try(var.auto_mode.truemark_nodeclass_default.subnetSelector, {
            network = "private"
          })
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
        Name                     = "${var.cluster_name}-truemark-default"
        "karpenter.sh/discovery" = var.cluster_name
      }
    }
  }

  depends_on = [
    module.auto_mode_helm
  ]
}

## Create default truemark nodepools for arm64 and amd64
resource "kubernetes_manifest" "auto_mode_node_pool" {
  for_each = var.enable_auto_mode && var.create_kubernetes_resources ? local.auto_mode_node_pools : {}

  manifest = {
    apiVersion = "karpenter.sh/v1"
    kind       = "NodePool"
    metadata = {
      name = each.value.name
    }
    spec = {
      disruption = {
        budgets = [
          {
            nodes = "10%"
          }
        ]
        consolidationPolicy = each.value.consolidationPolicy
        expireAfter         = each.value.expireAfter
      }
      template = {
        spec = {
          nodeClassRef = {
            name = "truemark"
          }
          taints = [
            {
              key    = "karpenter.sh/nodepool"
              value  = each.value.name
              effect = "NoSchedule"
            }
          ]
          requirements = each.value.requirements
        }
      }
      weight = each.value.weight
    }
  }

  depends_on = [
    kubernetes_manifest.auto_mode_node_class
  ]
}
