################################################################################
# Cert Manager Configuration
################################################################################

## Variables

# Enable or disable cert-manager add-on
variable "enable_cert_manager" {
  description = "Flag to enable or disable the cert-manager add-on."
  type        = bool
  default     = false
}

# Configuration for cert-manager Helm chart
variable "cert_manager" {
  description = <<-EOT
    Configuration for the cert-manager add-on.
    Allows customization of various aspects such as chart version, namespace, role creation,
    service account name, and additional Helm values or settings.
  EOT
  type = object({
    chart_version                 = optional(string, "v1.14.3")
    repository                    = optional(string, "https://charts.jetstack.io")
    chart                         = optional(string, "cert-manager")
    name                          = optional(string, "cert-manager")
    description                   = optional(string, "A Helm chart to deploy cert-manager")
    namespace                     = optional(string, "cert-manager")
    create_namespace              = optional(bool, true)
    create_role                   = optional(bool, true)
    role_name                     = optional(string, "cert-manager")
    role_name_use_prefix          = optional(bool, true)
    role_description              = optional(string, "IRSA for cert-manager project")
    allow_self_assume_role        = optional(bool, true)
    policy_name_use_prefix        = optional(bool, true)
    policy_description            = optional(string, "IAM Policy for cert-manager")
    service_account_name          = optional(string, "cert-manager")
    source_policy_documents       = optional(list(string), [])
    override_policy_documents     = optional(list(string), [])
    role_policies                 = optional(map(any), {})
    use_system_critical_nodegroup = optional(bool, false)
    set = optional(list(object({
      name  = string
      value = string
    })), [])
    values = optional(list(string), [])
  })
  default = {}
}

# List of Route53 Hosted Zone ARNs used by cert-manager for DNS record management
variable "cert_manager_route53_hosted_zone_arns" {
  description = "List of Route53 Hosted Zone ARNs used by cert-manager to create DNS records."
  type        = list(string)
  default     = ["arn:aws:route53:::hostedzone/*"]
}

## Locals

# Local variables to dynamically compute cert-manager configurations
locals {
  cert_manager_service_account = try(var.cert_manager.service_account_name, "cert-manager")
  create_cert_manager_irsa     = var.enable_cert_manager && length(var.cert_manager_route53_hosted_zone_arns) > 0
  cert_manager_namespace       = try(var.cert_manager.namespace, "cert-manager")
  cert_manager_use_system_critical_nodegroup = var.cert_manager.use_system_critical_nodegroup ? jsonencode({
    nodeSelector = var.critical_addons_node_selector
    tolerations  = var.critical_addons_node_tolerations
  }) : null
  cert_manager_install_crd_value = tonumber(split(".", var.cert_manager.chart_version)[1]) >= 15 ? [
    { name = "crds.install", value = "true" },
    { name = "crds.keep", value = "true" }
    ] : [
    { name = "installCRDs", value = "true" }
  ]
}

################################################################################
# IAM Policy for cert-manager
################################################################################

data "aws_iam_policy_document" "cert_manager" {
  count = local.create_cert_manager_irsa ? 1 : 0

  source_policy_documents   = lookup(var.cert_manager, "source_policy_documents", [])
  override_policy_documents = lookup(var.cert_manager, "override_policy_documents", [])

  statement {
    actions   = ["route53:GetChange"]
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

################################################################################
# Helm Release for cert-manager
################################################################################

module "cert_manager" {
  source  = "aws-ia/eks-blueprints-addon/aws"
  version = "1.1.1"

  create = var.enable_cert_manager

  # Disable Helm release if using GitOps
  create_release = var.create_kubernetes_resources

  # Helm chart details
  name             = try(var.cert_manager.name, "cert-manager")
  description      = try(var.cert_manager.description, "A Helm chart to deploy cert-manager")
  namespace        = local.cert_manager_namespace
  create_namespace = try(var.cert_manager.create_namespace, true)
  chart            = try(var.cert_manager.chart, "cert-manager")
  chart_version    = try(var.cert_manager.chart_version, "v1.14.3")
  repository       = try(var.cert_manager.repository, "https://charts.jetstack.io")

  # Helm values
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
      { name = "serviceAccount.name", value = local.cert_manager_service_account }
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

  # OIDC provider configuration
  oidc_providers = {
    this = {
      provider_arn    = var.oidc_provider_arn
      service_account = local.cert_manager_service_account
    }
  }
}
