################################################################################
# External Secrets Configuration
################################################################################

## Variables

# Enable or disable External Secrets operator add-on
variable "enable_external_secrets" {
  description = "Flag to enable or disable the External Secrets operator add-on."
  type        = bool
  default     = false
}

# Configuration for External Secrets Helm chart
variable "external_secrets" {
  description = <<-EOT
    Configuration for the External Secrets operator add-on.
    Supports customization of namespace, IAM roles, Helm chart values, and settings.
  EOT
  type = object({
    name             = optional(string, "external-secrets")
    description      = optional(string, "A Helm chart to deploy external-secrets")
    namespace        = optional(string, "external-secrets")
    create_namespace = optional(bool, true)
    chart            = optional(string, "external-secrets")
    chart_version    = optional(string, "0.9.13")
    repository       = optional(string, "https://charts.external-secrets.io")
    set = optional(list(object({
      name  = string
      value = string
    })), [])
    set_sensitive = optional(list(object({
      name  = string
      value = string
    })), [])
    create_role               = optional(bool, true)
    role_name                 = optional(string, "external-secrets")
    role_name_use_prefix      = optional(bool, true)
    role_path                 = optional(string, "/")
    role_description          = optional(string, "IRSA for external-secrets operator")
    role_policies             = optional(map(any), {})
    policy_name_use_prefix    = optional(bool, true)
    policy_description        = optional(string, "IAM Policy for external-secrets operator")
    source_policy_documents   = optional(list(string), [])
    override_policy_documents = optional(list(string), [])
    service_account_name      = optional(string, "external-secrets-sa")
  })
  default = {}
}

# List of SSM Parameter ARNs that External Secrets will manage
variable "external_secrets_ssm_parameter_arns" {
  description = "List of SSM Parameter ARNs that contain secrets to mount using External Secrets."
  type        = list(string)
  default     = ["arn:aws:ssm:*:*:parameter/*"]
}

# List of Secrets Manager ARNs that External Secrets will manage
variable "external_secrets_secrets_manager_arns" {
  description = "List of Secrets Manager ARNs that contain secrets to mount using External Secrets."
  type        = list(string)
  default     = ["arn:aws:secretsmanager:*:*:secret:*"]
}

# List of KMS Key ARNs used by Secrets Manager for decrypting secrets
variable "external_secrets_kms_key_arns" {
  description = "List of KMS Key ARNs used by Secrets Manager for decrypting secrets managed by External Secrets."
  type        = list(string)
  default     = ["arn:aws:kms:*:*:key/*"]
}

## Locals

# Local variables for namespace and service account
locals {
  external_secrets_service_account = try(var.external_secrets.service_account_name, "external-secrets-sa")
  external_secrets_namespace       = try(var.external_secrets.namespace, "external-secrets")
}

################################################################################
# IAM Policy for External Secrets
################################################################################

data "aws_iam_policy_document" "external_secrets" {
  count = var.enable_external_secrets ? 1 : 0

  source_policy_documents   = lookup(var.external_secrets, "source_policy_documents", [])
  override_policy_documents = lookup(var.external_secrets, "override_policy_documents", [])

  dynamic "statement" {
    for_each = length(var.external_secrets_ssm_parameter_arns) > 0 ? [1] : []

    content {
      actions   = ["ssm:DescribeParameters"]
      resources = ["*"]
    }
  }

  dynamic "statement" {
    for_each = length(var.external_secrets_ssm_parameter_arns) > 0 ? [1] : []

    content {
      actions = [
        "ssm:GetParameter",
        "ssm:GetParameters",
      ]
      resources = var.external_secrets_ssm_parameter_arns
    }
  }

  dynamic "statement" {
    for_each = length(var.external_secrets_secrets_manager_arns) > 0 ? [1] : []

    content {
      actions   = ["secretsmanager:ListSecrets"]
      resources = ["*"]
    }
  }

  dynamic "statement" {
    for_each = length(var.external_secrets_secrets_manager_arns) > 0 ? [1] : []

    content {
      actions = [
        "secretsmanager:GetResourcePolicy",
        "secretsmanager:GetSecretValue",
        "secretsmanager:DescribeSecret",
        "secretsmanager:ListSecretVersionIds",
      ]
      resources = var.external_secrets_secrets_manager_arns
    }
  }

  dynamic "statement" {
    for_each = length(var.external_secrets_kms_key_arns) > 0 ? [1] : []

    content {
      actions   = ["kms:Decrypt"]
      resources = var.external_secrets_kms_key_arns
    }
  }
}

################################################################################
# Helm Release for External Secrets
################################################################################

module "external_secrets" {
  source  = "aws-ia/eks-blueprints-addon/aws"
  version = "1.1.1"

  # Enable or disable the creation of this module
  create = var.enable_external_secrets

  # Flag to disable the Helm release (useful when deploying via GitOps)
  create_release = var.create_kubernetes_resources

  # Helm chart configuration
  name             = try(var.external_secrets.name, "external-secrets")
  description      = try(var.external_secrets.description, "A Helm chart to deploy external-secrets")
  namespace        = local.external_secrets_namespace
  create_namespace = try(var.external_secrets.create_namespace, true)
  chart            = try(var.external_secrets.chart, "external-secrets")
  chart_version    = try(var.external_secrets.chart_version, "0.9.13")
  repository       = try(var.external_secrets.repository, "https://charts.external-secrets.io")

  # Additional Helm settings
  set = concat([
    {
      name  = "serviceAccount.name"
      value = local.external_secrets_service_account
    },
    {
      name  = "webhook.port"
      value = var.enable_eks_fargate ? "9443" : "10250"
    }],
    try(var.external_secrets.set, [])
  )
  set_sensitive = try(var.external_secrets.set_sensitive, [])

  # IAM role for service account (IRSA)
  set_irsa_names       = ["serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"]
  create_role          = try(var.external_secrets.create_role, true)
  role_name            = try(var.external_secrets.role_name, "external-secrets")
  role_name_use_prefix = try(var.external_secrets.role_name_use_prefix, true)
  role_path            = try(var.external_secrets.role_path, "/")
  role_description     = try(var.external_secrets.role_description, "IRSA for external-secrets operator")
  role_policies        = lookup(var.external_secrets, "role_policies", {})

  # IAM policy for the role
  source_policy_documents = data.aws_iam_policy_document.external_secrets[*].json
  policy_name_use_prefix  = try(var.external_secrets.policy_name_use_prefix, true)
  policy_description      = try(var.external_secrets.policy_description, "IAM Policy for external-secrets operator")

  # OIDC provider configuration
  oidc_providers = {
    this = {
      provider_arn = var.oidc_provider_arn
      # Namespace is inherited from chart
      service_account = local.external_secrets_service_account
    }
  }

  # Tags for resources
  tags = var.tags
}
