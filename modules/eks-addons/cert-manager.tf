################################################################################
# Cert Manager
################################################################################

## Variables
variable "enable_cert_manager" {
  description = "Enable cert-manager add-on"
  type        = bool
  default     = false
}

variable "cert_manager" {
  description = "cert-manager add-on configuration values"
  type        = any
  default     = {}
}

variable "cert_manager_route53_hosted_zone_arns" {
  description = "List of Route53 Hosted Zone ARNs that are used by cert-manager to create DNS records"
  type        = list(string)
  default     = ["arn:aws:route53:::hostedzone/*"]
}


## Locals
locals {
  cert_manager_service_account               = try(var.cert_manager.service_account_name, "cert-manager")
  create_cert_manager_irsa                   = var.enable_cert_manager && length(var.cert_manager_route53_hosted_zone_arns) > 0
  cert_manager_namespace                     = try(var.cert_manager.namespace, "cert-manager")
  cert_manager_use_system_critical_nodegroup = var.cert_manager.use_system_critical_nodegroup ? jsonencode({ nodeSelector = var.critical_addons_node_selector, tolerations = var.critical_addons_node_tolerations }) : null
  cert_manager_install_crd_value             = tonumber(split(".", var.cert_manager.chart_version)[1]) >= 15 ? [{ name = "crds.install", value = "true" }, { name = "crds.keep", value = "true" }] : [{ name = "installCRDs", value = "true" }]
}

data "aws_iam_policy_document" "cert_manager" {
  count = local.create_cert_manager_irsa ? 1 : 0

  source_policy_documents   = lookup(var.cert_manager, "source_policy_documents", [])
  override_policy_documents = lookup(var.cert_manager, "override_policy_documents", [])

  statement {
    actions   = ["route53:GetChange", ]
    resources = ["arn:${var.aws_partition}:route53:::change/*"]
  }

  statement {
    actions = [
      "route53:ChangeResourceRecordSets",
      "route53:ListResourceRecordSets",
    ]
    resources = var.cert_manager_route53_hosted_zone_arns
  }

  statement {
    actions   = ["route53:ListHostedZonesByName"]
    resources = ["*"]
  }
}

## Helm release
module "cert_manager" {
  source  = "aws-ia/eks-blueprints-addon/aws"
  version = "1.1.1"

  create = var.enable_cert_manager

  # Disable helm release
  create_release = var.create_kubernetes_resources

  # https://github.com/cert-manager/cert-manager/blob/master/deploy/charts/cert-manager/Chart.template.yaml
  name             = try(var.cert_manager.name, "cert-manager")
  description      = try(var.cert_manager.description, "A Helm chart to deploy cert-manager")
  namespace        = local.cert_manager_namespace
  create_namespace = try(var.cert_manager.create_namespace, true)
  chart            = try(var.cert_manager.chart, "cert-manager")
  chart_version    = try(var.cert_manager.chart_version, "v1.14.3")
  repository       = try(var.cert_manager.repository, "https://charts.jetstack.io")
  values = concat(
    try(var.cert_manager.values, []),
    var.cert_manager.use_system_critical_nodegroup ? [
      jsonencode({
        tolerations  = var.critical_addons_node_tolerations
        nodeSelector = var.critical_addons_node_selector
        cainjector = {
          tolerations  = var.critical_addons_node_tolerations
          nodeSelector = var.critical_addons_node_selector
        }
        webhook = {
          tolerations  = var.critical_addons_node_tolerations
          nodeSelector = var.critical_addons_node_selector
        }
        startupapicheck = {
          tolerations  = var.critical_addons_node_tolerations
          nodeSelector = var.critical_addons_node_selector
        }
      })
    ] : []
  )
  set = concat(
    [
      {
        name  = "serviceAccount.name"
        value = local.cert_manager_service_account
      }
    ],
    local.cert_manager_install_crd_value,
    try(var.cert_manager.set, [])
  )

  # IAM role for service account (IRSA)
  set_irsa_names       = ["serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"]
  create_role          = local.create_cert_manager_irsa && try(var.cert_manager.create_role, true)
  role_name            = try(var.cert_manager.role_name, "cert-manager")
  role_name_use_prefix = try(var.cert_manager.role_name_use_prefix, true)
  role_description     = try(var.cert_manager.role_description, "IRSA for cert-manger project")
  role_policies        = lookup(var.cert_manager, "role_policies", {})

  allow_self_assume_role  = try(var.cert_manager.allow_self_assume_role, true)
  source_policy_documents = data.aws_iam_policy_document.cert_manager[*].json
  policy_name_use_prefix  = try(var.cert_manager.policy_name_use_prefix, true)
  policy_description      = try(var.cert_manager.policy_description, "IAM Policy for cert-manager")

  oidc_providers = {
    this = {
      provider_arn = var.oidc_provider_arn
      # namespace is inherited from chart
      service_account = local.cert_manager_service_account
    }
  }
}
