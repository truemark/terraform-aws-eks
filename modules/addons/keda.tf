################################################################################
# Keda
################################################################################
variable "enable_keda" {
  description = "Enable Keda add-on"
  type        = bool
  default     = false
}

variable "keda" {
  description = "Keda add-on configuration values"
  type        = any
  default     = {}
}

variable "keda_user_aws_scalers" {
  description = "Enable Keda to use AWS based scalers"
  type        = bool
  default     = true
}

locals {
  create_release       = var.create_kubernetes_resources
  keda_namespace       = try(var.keda.namespace, "keda")
  keda_service_account = try(var.keda.service_account_name, "keda-*")
}

data "aws_iam_policy_document" "keda" {
  count = var.keda_user_aws_scalers ? 1 : 0

  statement {
    actions   = ["cloudwatch:GetMetricData", "cloudwatch:ListMetrics"]
    resources = ["*"]
  }
}

module "keda" {
  source  = "aws-ia/eks-blueprints-addon/aws"
  version = "1.1.1"

  create = var.enable_keda

  create_release = var.create_kubernetes_resources

  name             = try(var.keda.name, "keda")
  description      = try(var.keda.description, "A Helm chart to install Keda")
  namespace        = local.keda_namespace
  create_namespace = try(var.keda.create_namespace, true)
  chart            = try(var.keda.chart, "keda")
  chart_version    = try(var.keda.chart_version, "2.16.0")
  repository       = try(var.keda.repository, "https://kedacore.github.io/charts")
  set = concat(
    [
      {
        name  = "serviceAccount.name"
        value = local.keda_service_account
      }
    ],
    try(var.keda.set, [])
  )
  # IAM role for service account (IRSA)
  set_irsa_names       = ["podIdentity.aws.irsa.roleArn"]
  create_role          = var.keda_user_aws_scalers && try(var.keda.create_role, true)
  role_name            = try(var.keda.role_name, "keda")
  role_name_use_prefix = try(var.keda.role_name_use_prefix, true)
  role_description     = try(var.keda.role_description, "IRSA for keda project")
  role_policies        = lookup(var.keda, "role_policies", {})

  allow_self_assume_role     = try(var.keda.allow_self_assume_role, true)
  assume_role_condition_test = "StringLike"
  source_policy_documents    = data.aws_iam_policy_document.keda[*].json
  policy_description         = try(var.keda.policy_description, "IAM Policy for keda")
  oidc_providers = {
    this = {
      provider_arn = var.oidc_provider_arn
      # namespace is inherited from chart
      service_account = local.keda_service_account
    }
  }
  tags = var.tags
}
