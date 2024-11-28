################################################################################
# truemark_observability.thanos Configuration
################################################################################

# Enable or disable truemark_observability.thanos add-on
variable "enable_truemark_observability" {
  description = "Flag to enable or disable the truemark_observability.thanos controller add-on."
  type        = bool
  default     = false
}

variable "truemark_observability" {

}

locals {
  thanos_name                = "thanos"
  thanos_service_account     = try(var.truemark_observability.thanos.service_account_name, "k8s-observabilility-thanos-*")
  prometheus_service_account = try(var.truemark_observability.kubePrometheusStack.service_account_name, "k8s-observabilility-prometheus")
}


################################################################################
data "aws_iam_policy_document" "prometheus_iam_role_policy" {
  statement {
    actions = [
      "s3:ListBucket",
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
      "s3:GetObjectTagging",
      "s3:PutObjectTagging"
    ]

    resources = [
      module.thanos_s3_bucket.s3_bucket_arn,
      "${module.thanos_s3_bucket.s3_bucket_arn}/*",
    ]
  }
  statement {
    actions = [
      "sns:*"
    ]
    resources = [var.truemark_observability.alertmanager.alerts_topic_arn]
  }
  statement {
    actions = [
      "kms:GenerateDataKey",
      "kms:Decrypt"
    ]
    resources = ["*"]
  }
}

module "prometheus_iam_policy" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "5.48.0"
  name    = "prometheus-iam-policy-test"
  policy  = data.aws_iam_policy_document.prometheus_iam_role_policy.json
}

module "prometheus_iam_role" {
  count     = var.truemark_observability.kube_prometheus_stack.enabled ? 1 : 0
  source    = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version   = "5.48.0"
  role_name = "prometheus-iam-role"
  oidc_providers = {
    this = {
      provider_arn               = var.oidc_provider_arn
      namespace_service_accounts = ["observability:${local.prometheus_service_account}", "observability:k8s-observabilility-alertmanager"]
    }
  }
  role_policy_arns = merge(
    var.truemark_observability.thanos.enabled ? { prometheus = module.prometheus_iam_policy.arn } : {}
  )
}

## Grafana
resource "random_password" "grafana_admin_password" {
  length = 12
}


## Thanos
module "thanos_s3_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 3.0"

  create_bucket = try(lookup(var.truemark_observability.thanos, "enabled", var.enable_truemark_observability), false)

  bucket_prefix = "${var.aws_account_id}-${local.thanos_name}-"

  # Allow deletion of non-empty bucket
  # NOTE: This is enabled for example usage only, you should not enable this for production workloads
  force_destroy = true

  attach_deny_insecure_transport_policy = true
  attach_require_latest_tls_policy      = true

  acl = "private"

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  control_object_ownership = true
  object_ownership         = "BucketOwnerPreferred"

  versioning = {
    status     = false
    mfa_delete = false
  }

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm = "AES256"
      }
    }
  }
}

data "aws_iam_policy_document" "thanos_iam_role_policy" {
  count = var.truemark_observability.thanos.enabled ? 1 : 0
  statement {
    actions = [
      "s3:ListBucket",
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
      "s3:GetObjectTagging",
      "s3:PutObjectTagging"
    ]

    resources = [
      module.thanos_s3_bucket.s3_bucket_arn,
      "${module.thanos_s3_bucket.s3_bucket_arn}/*",
    ]
  }
}

module "thanos" {
  source  = "aws-ia/eks-blueprints-addon/aws"
  version = "1.1.1"

  create = var.truemark_observability.thanos.enabled

  # Disable helm release
  create_release = var.create_kubernetes_resources

  # https://github.com/aws/truemark_observability.thanos/blob/main/charts/truemark_observability.thanos/Chart.yaml
  name             = try(var.truemark_observability.thanos.name, "thanos")
  description      = try(var.truemark_observability.thanos.description, "A Helm chart to deploy thanos")
  namespace        = try(var.truemark_observability.thanos.namespace, "observability")
  create_namespace = try(var.truemark_observability.thanos.create_namespace, true)
  chart            = try(var.truemark_observability.thanos.chart, "thanos")
  chart_version    = try(var.truemark_observability.thanos.chart_version, "1.0.7")
  repository       = try(var.truemark_observability.thanos.repository, "oci://registry-1.docker.io/bitnamicharts")
  #   values = concat(try(var.truemark_observability.thanos.values, []), var.truemark_observability.thanos.use_system_critical_nodegroup ? [
  #     jsonencode({
  #       tolerations  = var.critical_addons_node_tolerations
  #       nodeSelector = var.critical_addons_node_selector
  #     })
  #     ] : []
  #   )
  skip_crds = try(var.truemark_observability.thanos.skip_crds, true)

  timeout          = try(var.truemark_observability.thanos.timeout, null)
  verify           = try(var.truemark_observability.thanos.verify, null)
  disable_webhooks = try(var.truemark_observability.thanos.disable_webhooks, null)

  create_role                = try(var.truemark_observability.thanos.create_role, true)
  set_irsa_names             = ["serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"]
  role_name                  = try(var.truemark_observability.thanos.role_name, "truemark-observability-thanos")
  role_name_use_prefix       = try(var.truemark_observability.thanos.role_name_use_prefix, true)
  role_policies              = lookup(var.truemark_observability.thanos, "role_policies", {})
  assume_role_condition_test = "StringLike"
  source_policy_documents    = data.aws_iam_policy_document.thanos_iam_role_policy[*].json
  policy_statements          = lookup(var.truemark_observability.thanos, "policy_statements", [])
  policy_name                = try(var.truemark_observability.thanos.policy_name, null)
  policy_name_use_prefix     = try(var.truemark_observability.thanos.policy_name_use_prefix, true)
  policy_path                = try(var.truemark_observability.thanos.policy_path, null)
  policy_description         = try(var.truemark_observability.thanos.policy_description, "IAM Policy for AWS Load Balancer Controller")

  oidc_providers = {
    this = {
      provider_arn    = var.oidc_provider_arn
      service_account = local.thanos_service_account
    }
  }

  tags = var.tags
}
