################################################################################
# Karpenter Configuration
################################################################################

## Variables

# Enable or disable Karpenter add-on
variable "enable_karpenter" {
  description = "Flag to enable or disable the Karpenter controller add-on."
  type        = bool
  default     = false
}

# Configuration for Karpenter Helm chart
variable "karpenter" {
  description = <<-EOT
    Configuration for the Karpenter add-on.
    Supports customization of namespace, IAM roles, Helm chart values, CRD configurations,
    and node pools for arm64 and amd64 architectures.
  EOT
  type = object({
    name             = optional(string, "karpenter")
    description      = optional(string, "A Helm chart to deploy Karpenter")
    namespace        = optional(string, "karpenter")
    create_namespace = optional(bool, true)
    chart            = optional(string, "karpenter")
    chart_version    = optional(string, "1.0.7")
    repository       = optional(string, "oci://public.ecr.aws/karpenter")
    values           = optional(list(string), [])
    set = optional(list(object({
      name  = string
      value = string
    })), [])
    set_sensitive = optional(list(object({
      name  = string
      value = string
    })), [])
    skip_crds                         = optional(bool, true)
    timeout                           = optional(string, null)
    verify                            = optional(bool, null)
    disable_webhooks                  = optional(bool, null)
    enable_karpenter_crd_webhook      = optional(bool, false)
    enable_pod_identity               = optional(bool, true)
    create_pod_identity_association   = optional(bool, true)
    enable_v1_permissions             = optional(bool, true)
    enable_irsa                       = optional(bool, false)
    node_iam_role_additional_policies = optional(map(string), {})
    use_system_critical_nodegroup     = optional(bool, false)
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
  karpenter_service_account = try(var.karpenter.service_account_name, "karpenter")
  karpenter_namespace       = try(var.karpenter.namespace, "karpenter")
  karpenter_crd_webhook_configs = var.karpenter.enable_karpenter_crd_webhook ? [
    { name = "webhook.enabled", value = "true" },
    { name = "webhook.serviceNamespace", value = local.karpenter_namespace },
  ] : []
  karpenter_node_pools = {
    arm64 = {
      name                = "truemark-arm64"
      architecture        = "arm64"
      requirements        = try(var.karpenter.truemark_node_pool_default.arm64.requirements, [])
      consolidationPolicy = try(var.karpenter.truemark_node_pool_default.arm64.consolidation_policy, "WhenUnderutilized")
      expireAfter         = try(var.karpenter.truemark_node_pool_default.arm64.expire_after, "720h")
      weight              = try(var.karpenter.truemark_node_pool_default.arm64.node_pool_weight, 10)
      requirements = try(var.karpenter.truemark_node_pool_default.arm64.requirements, [
        {
          key      = "karpenter.k8s.aws/instance-category"
          operator = "In"
          values   = ["m", "c", "r"]
        },
        {
          key      = "karpenter.k8s.aws/instance-cpu"
          operator = "In"
          values   = ["4", "8", "16"]
        },
        {
          key      = "karpenter.k8s.aws/instance-hypervisor"
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
      requirements        = try(var.karpenter.truemark_node_pool_default.amd64.requirements, [])
      consolidationPolicy = try(var.karpenter.truemark_node_pool_default.amd64.consolidation_policy, "WhenUnderutilized")
      expireAfter         = try(var.karpenter.truemark_node_pool_default.amd64.expire_after, "720h")
      weight              = try(var.karpenter.truemark_node_pool_default.amd64.node_pool_weight, 10)
      requirements = try(var.karpenter.truemark_node_pool_default.amd64.requirements, [
        {
          key      = "karpenter.k8s.aws/instance-category"
          operator = "In"
          values   = ["m", "c", "r"]
        },
        {
          key      = "karpenter.k8s.aws/instance-cpu"
          operator = "In"
          values   = ["4", "8", "16"]
        },
        {
          key      = "karpenter.k8s.aws/instance-hypervisor"
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

module "karpenter" {
  count   = var.enable_karpenter ? 1 : 0
  source  = "terraform-aws-modules/eks/aws//modules/karpenter"
  version = "20.28.0"

  cluster_name = var.cluster_name

  enable_v1_permissions = try(var.karpenter.enable_v1_permissions, true)

  enable_pod_identity             = try(var.karpenter.enable_pod_identity, true)
  create_pod_identity_association = try(var.karpenter.create_pod_identity_association, true)
  namespace                       = local.karpenter_namespace
  enable_irsa                     = try(var.karpenter.enable_irsa, false)

  node_iam_role_additional_policies = merge({
    AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  }, try(var.karpenter.node_iam_role_additional_policies, {}))
}

module "karpenter_crds" {
  source  = "aws-ia/eks-blueprints-addon/aws"
  version = "1.1.1"

  create = var.enable_karpenter

  # Disable helm release
  create_release = var.create_kubernetes_resources

  # https://github.com/aws/karpenter/blob/main/charts/karpenter/Chart.yaml
  name             = try(var.karpenter.crd_release_name, "karpenter-crd")
  description      = try(var.karpenter.description, "A Helm chart to deploy Karpenter")
  namespace        = try(var.karpenter.namespace, "karpenter")
  create_namespace = try(var.karpenter.create_namespace, true)
  chart            = try(var.karpenter.chart, "karpenter-crd")
  chart_version    = try(var.karpenter.chart_version, "1.0.7")
  repository       = try(var.karpenter.repository, "oci://public.ecr.aws/karpenter")
  values           = try(var.karpenter.values, [])
  timeout          = try(var.karpenter.timeout, null)
  verify           = try(var.karpenter.verify, null)
  disable_webhooks = try(var.karpenter.disable_webhooks, null)
  set = concat(
    try(var.karpenter.set, []),
    local.karpenter_crd_webhook_configs
  )
  set_sensitive = try(var.karpenter.set_sensitive, [])

  tags = var.tags
}

module "karpenter_helm" {
  source  = "aws-ia/eks-blueprints-addon/aws"
  version = "1.1.1"

  create = var.enable_karpenter

  # Disable helm release
  create_release = var.create_kubernetes_resources

  # https://github.com/aws/karpenter/blob/main/charts/karpenter/Chart.yaml
  name             = try(var.karpenter.name, "karpenter")
  description      = try(var.karpenter.description, "A Helm chart to deploy Karpenter")
  namespace        = try(var.karpenter.namespace, "karpenter")
  create_namespace = try(var.karpenter.create_namespace, true)
  chart            = try(var.karpenter.chart, "karpenter")
  chart_version    = try(var.karpenter.chart_version, "1.0.7")
  repository       = try(var.karpenter.repository, "oci://public.ecr.aws/karpenter")
  values = concat(try(var.karpenter.values, []), var.karpenter.use_system_critical_nodegroup ? [
    jsonencode({
      tolerations  = var.critical_addons_node_tolerations
      nodeSelector = var.critical_addons_node_selector
    })
    ] : []
  )
  skip_crds = try(var.karpenter.skip_crds, true)

  timeout          = try(var.karpenter.timeout, null)
  verify           = try(var.karpenter.verify, null)
  disable_webhooks = try(var.karpenter.disable_webhooks, null)
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
        value = module.karpenter[0].queue_name
      },
      {
        name  = "serviceAccount.name"
        value = "karpenter"
      },
      {
        name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
        value = module.karpenter[0].iam_role_arn
      }
    ],
    try(var.karpenter.set, [])
  )
  set_sensitive = try(var.karpenter.set_sensitive, [])

  tags       = var.tags
  depends_on = [module.karpenter_crds]
}

## Create default truemark nodepool
resource "kubernetes_manifest" "karpenter_node_class" {
  count = var.enable_karpenter && var.create_kubernetes_resources ? 1 : 0

  manifest = {
    apiVersion = "karpenter.k8s.aws/v1beta1"
    kind       = "EC2NodeClass"
    metadata = {
      name = "truemark"
    }
    spec = {
      amiFamily = try(var.karpenter.truemark_nodeclass_default.ami_family, "bottlerocket")
      blockDeviceMappings = try(var.karpenter.truemark_nodeclass_default.block_device_mappings, [
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
      role = module.karpenter[0].node_iam_role_name
      subnetSelectorTerms = [
        {
          tags = try(var.karpenter.truemark_nodeclass_default.subnetSelector, {
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
    module.karpenter_crds,
    module.karpenter_helm
  ]
}

## Create default truemark nodepools for arm64 and amd64
resource "kubernetes_manifest" "karpenter_node_pool" {
  for_each = var.enable_karpenter && var.create_kubernetes_resources ? local.karpenter_node_pools : {}

  manifest = {
    apiVersion = "karpenter.sh/v1beta1"
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
    kubernetes_manifest.karpenter_node_class
  ]
}
