################################################################################
# External DNS
################################################################################
variable "enable_external_dns" {
  description = "Enable external-dns operator add-on"
  type        = bool
  default     = false
}

variable "external_dns" {
  description = "external-dns add-on configuration values"
  type        = any
  default     = {}
}

variable "external_dns_route53_zone_arns" {
  description = "List of Route53 zones ARNs which external-dns will have access to create/manage records (if using Route53)"
  type        = list(string)
  default     = []
}

locals {
  external_dns_service_account = try(var.external_dns.service_account_name, "external-dns-sa")
  external_dns_namespace       = try(var.external_dns.namespace, "external-dns")
}

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

module "external_dns" {
  source  = "aws-ia/eks-blueprints-addon/aws"
  version = "1.1.1"

  create = var.enable_external_dns

  # Disable helm release
  create_release = var.create_kubernetes_resources

  # https://github.com/kubernetes-sigs/external-dns/tree/master/charts/external-dns/Chart.yaml
  name             = try(var.external_dns.name, "external-dns")
  description      = try(var.external_dns.description, "A Helm chart to deploy external-dns")
  namespace        = local.external_dns_namespace
  create_namespace = try(var.external_dns.create_namespace, true)
  chart            = try(var.external_dns.chart, "external-dns")
  chart_version    = try(var.external_dns.chart_version, "1.14.3")
  repository       = try(var.external_dns.repository, "https://kubernetes-sigs.github.io/external-dns/")
  values           = try(var.external_dns.values, ["provider: aws"])

  timeout                    = try(var.external_dns.timeout, null)
  repository_key_file        = try(var.external_dns.repository_key_file, null)
  repository_cert_file       = try(var.external_dns.repository_cert_file, null)
  repository_ca_file         = try(var.external_dns.repository_ca_file, null)
  repository_username        = try(var.external_dns.repository_username, null)
  repository_password        = try(var.external_dns.repository_password, null)
  devel                      = try(var.external_dns.devel, null)
  verify                     = try(var.external_dns.verify, null)
  keyring                    = try(var.external_dns.keyring, null)
  disable_webhooks           = try(var.external_dns.disable_webhooks, null)
  reuse_values               = try(var.external_dns.reuse_values, null)
  reset_values               = try(var.external_dns.reset_values, null)
  force_update               = try(var.external_dns.force_update, null)
  recreate_pods              = try(var.external_dns.recreate_pods, null)
  cleanup_on_fail            = try(var.external_dns.cleanup_on_fail, null)
  max_history                = try(var.external_dns.max_history, null)
  atomic                     = try(var.external_dns.atomic, null)
  skip_crds                  = try(var.external_dns.skip_crds, null)
  render_subchart_notes      = try(var.external_dns.render_subchart_notes, null)
  disable_openapi_validation = try(var.external_dns.disable_openapi_validation, null)
  wait                       = try(var.external_dns.wait, false)
  wait_for_jobs              = try(var.external_dns.wait_for_jobs, null)
  dependency_update          = try(var.external_dns.dependency_update, null)
  replace                    = try(var.external_dns.replace, null)
  lint                       = try(var.external_dns.lint, null)

  postrender = try(var.external_dns.postrender, [])
  set = concat([
    {
      name  = "serviceAccount.name"
      value = local.external_dns_service_account
    }],
    try(var.external_dns.set, [])
  )
  set_sensitive = try(var.external_dns.set_sensitive, [])

  # IAM role for service account (IRSA)
  set_irsa_names                = ["serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"]
  create_role                   = try(var.external_dns.create_role, true) && length(var.external_dns_route53_zone_arns) > 0
  role_name                     = try(var.external_dns.role_name, "external-dns")
  role_name_use_prefix          = try(var.external_dns.role_name_use_prefix, true)
  role_path                     = try(var.external_dns.role_path, "/")
  role_permissions_boundary_arn = lookup(var.external_dns, "role_permissions_boundary_arn", null)
  role_description              = try(var.external_dns.role_description, "IRSA for external-dns operator")
  role_policies                 = lookup(var.external_dns, "role_policies", {})

  source_policy_documents = data.aws_iam_policy_document.external_dns[*].json
  policy_statements       = lookup(var.external_dns, "policy_statements", [])
  policy_name             = try(var.external_dns.policy_name, null)
  policy_name_use_prefix  = try(var.external_dns.policy_name_use_prefix, true)
  policy_path             = try(var.external_dns.policy_path, null)
  policy_description      = try(var.external_dns.policy_description, "IAM Policy for external-dns operator")

  oidc_providers = {
    this = {
      provider_arn = var.oidc_provider_arn
      # namespace is inherited from chart
      service_account = local.external_dns_service_account
    }
  }
}
