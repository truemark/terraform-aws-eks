################################################################################
# External DNS Configuration
################################################################################

## Variables

# Enable or disable External DNS add-on
variable "enable_external_dns" {
  description = "Flag to enable or disable the External DNS add-on."
  type        = bool
  default     = false
}

# Configuration for External DNS Helm chart
variable "external_dns" {
  description = <<-EOT
    Configuration for the External DNS add-on.
    Allows customization of various aspects such as chart version, namespace, IAM roles,
    and additional Helm values or settings.
  EOT
  type = object({
    name             = optional(string, "external-dns")
    description      = optional(string, "A Helm chart to deploy external-dns")
    namespace        = optional(string, "external-dns")
    create_namespace = optional(bool, true)
    chart            = optional(string, "external-dns")
    chart_version    = optional(string, "1.14.3")
    repository       = optional(string, "https://kubernetes-sigs.github.io/external-dns/")
    values           = optional(list(string), [])
    set = optional(list(object({
      name  = string
      value = string
    })), [])
    create_role                   = optional(bool, true)
    role_name                     = optional(string, "external-dns")
    role_name_use_prefix          = optional(bool, true)
    role_path                     = optional(string, "/")
    role_description              = optional(string, "IRSA for external-dns operator")
    role_policies                 = optional(map(any), {})
    policy_description            = optional(string, "IAM Policy for external-dns operator")
    use_system_critical_nodegroup = optional(bool, false)
    source_policy_documents       = optional(list(string), [])
    override_policy_documents     = optional(list(string), [])
    service_account_name          = optional(string, "external-dns")
  })
  default = {}
}

# List of Route53 zones ARNs which External DNS will manage
variable "external_dns_route53_zone_arns" {
  description = "List of Route53 zone ARNs which External DNS will have access to create/manage records (if using Route53)."
  type        = list(string)
  default     = []
}

## Locals

# Local variables to compute dynamic settings
locals {
  external_dns_service_account = try(var.external_dns.service_account_name, "external-dns")
  external_dns_namespace       = try(var.external_dns.namespace, "external-dns")
}

output "test" {
  value = var.external_dns_route53_zone_arns
}

################################################################################
# IAM Policy for External DNS
################################################################################

data "aws_iam_policy_document" "external_dns" {
  count = var.enable_external_dns && length(var.external_dns_route53_zone_arns) > 0 ? 1 : 0

  source_policy_documents   = lookup(var.external_dns, "source_policy_documents", [])
  override_policy_documents = lookup(var.external_dns, "override_policy_documents", [])

  statement {
    actions   = ["route53:ChangeResourceRecordSets"]
    resources = var.external_dns_route53_zone_arns
  }

  statement {
    actions   = ["route53:ListTagsForResource"]
    resources = var.external_dns_route53_zone_arns
  }

  statement {
    actions = [
      "route53:ListHostedZones",
      "route53:ListResourceRecordSets",
    ]
    resources = ["*"]
  }
}

################################################################################
# Helm Release for External DNS
################################################################################

module "external_dns" {
  source  = "aws-ia/eks-blueprints-addon/aws"
  version = "1.1.1"

  # Enable or disable the creation of this module
  create = var.enable_external_dns

  # Flag to disable the Helm release (useful when deploying via GitOps)
  create_release = var.create_kubernetes_resources

  # Helm chart configuration
  name             = try(var.external_dns.name, "external-dns")
  description      = try(var.external_dns.description, "A Helm chart to deploy external-dns")
  namespace        = local.external_dns_namespace
  create_namespace = try(var.external_dns.create_namespace, true)
  chart            = try(var.external_dns.chart, "external-dns")
  chart_version    = try(var.external_dns.chart_version, "1.14.3")
  repository       = try(var.external_dns.repository, "https://kubernetes-sigs.github.io/external-dns/")

  # Custom Helm values
  values = concat(
    try(var.external_dns.values, ["provider: aws"]),
    var.external_dns.use_system_critical_nodegroup ? [
      jsonencode({
        tolerations  = var.critical_addons_node_tolerations
        nodeSelector = var.critical_addons_node_selector
      })
    ] : []
  )

  # Additional Helm settings
  set = concat([
    {
      name  = "serviceAccount.name"
      value = local.external_dns_service_account
    }],
    try(var.external_dns.set, [])
  )

  # IAM role for service account (IRSA)
  set_irsa_names       = ["serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"]
  create_role          = try(var.external_dns.create_role, true) && length(var.external_dns_route53_zone_arns) > 0
  role_name            = try(var.external_dns.role_name, "external-dns")
  role_name_use_prefix = try(var.external_dns.role_name_use_prefix, true)
  role_path            = try(var.external_dns.role_path, "/")
  role_description     = try(var.external_dns.role_description, "IRSA for external-dns operator")
  role_policies        = lookup(var.external_dns, "role_policies", {})

  # IAM policy for the role
  source_policy_documents = data.aws_iam_policy_document.external_dns[*].json
  policy_description      = try(var.external_dns.policy_description, "IAM Policy for external-dns operator")

  # OIDC provider configuration
  oidc_providers = {
    this = {
      provider_arn = var.oidc_provider_arn
      # Namespace is inherited from chart
      service_account = local.external_dns_service_account
    }
  }
}
