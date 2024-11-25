################################################################################
# truemark_observability.thanos Configuration
################################################################################

## Variables

# Enable or disable truemark_observability.thanos add-on
variable "enable_truemark_observability" {
  description = "Flag to enable or disable the truemark_observability.thanos controller add-on."
  type        = bool
  default     = false
}

variable "truemark_observability" {
  default = {
    thanos = {}
    kube_prometheus_stack = {}
  }
}

locals {
  thanos_name                    = "thanos"
  loki_name = "loki"
  thanos_service_account         = try(var.truemark_observability.thanos.service_account_name, "k8s-observabilility-thanos-*")
  loki_service_account = try(var.truemark_observability.loki.service_account_name, "loki")
  prometheus_service_account = try(var.truemark_observability.kubePrometheusStack.service_account_name, "k8s-observabilility-prometheus")
}


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
    status     = true
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

################################################################################
module "prometheus_thanos_bucket_access_policy" {
  count = var.truemark_observability.kube_prometheus_stack.enabled && var.truemark_observability.thanos.enabled ? 1 : 0
  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "5.48.0"
  name = "prometheus-iam-policy"
  policy = data.aws_iam_policy_document.thanos_iam_role_policy[0].json
}

module "prometheus_iam_role" {
  count = var.truemark_observability.kube_prometheus_stack.enabled ? 1 : 0
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.48.0"
  role_name = "prometheus-iam-role"
  oidc_providers = {
    this = {
      provider_arn = var.oidc_provider_arn
      namespace_service_accounts = ["observability:${local.prometheus_service_account}"]
    }
  }
  role_policy_arns = merge(
    var.truemark_observability.thanos.enabled ? { thano_bucket_access = module.prometheus_thanos_bucket_access_policy[0].arn } : {}
  )
}

## Grafana
resource "random_password" "grafana_admin_password" {
  length = 12
}


## Loki
module "loki_s3_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 3.0"

  create_bucket = try(lookup(var.truemark_observability.loki, "enabled", var.enable_truemark_observability), false)

  bucket_prefix = "${var.aws_account_id}-${local.loki_name}-"

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
    status     = true
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

data "aws_iam_policy_document" "loki_iam_role_policy" {
  count = var.truemark_observability.loki.enabled ? 1 : 0
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
      module.loki_s3_bucket.s3_bucket_arn,
      "${module.loki_s3_bucket.s3_bucket_arn}/*",
    ]
  }
}

module "loki_bucket_access_policy" {
  count = var.truemark_observability.loki.enabled ? 1 : 0
  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "5.48.0"
  name = "loki-iam-policy"
  policy = data.aws_iam_policy_document.loki_iam_role_policy[0].json
}

module "loki_iam_role" {
  count = var.truemark_observability.loki.enabled ? 1 : 0
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.48.0"
  role_name = "loki-iam-role"
  assume_role_condition_test = "StringLike"
  oidc_providers = {
    this = {
      provider_arn = var.oidc_provider_arn
      namespace_service_accounts = ["observability:${local.loki_service_account}"]
    }
  }
  role_policy_arns = merge(
    { loki_bucket_access = module.loki_bucket_access_policy[0].arn }
  )
}

# module "kube_prometheus_stack" {
#   source  = "aws-ia/eks-blueprints-addon/aws"
#   version = "1.1.1"
#
#   create = var.truemark_observability.kubePrometheusStack.enabled
#
#   # Disable helm release
#   create_release = var.create_kubernetes_resources
#
#   # https://github.com/aws/truemark_observability.thanos/blob/main/charts/truemark_observability.thanos/Chart.yaml
#   name             = try(var.truemark_observability.kubePrometheusStack.name, "kube-prometheus-stack")
#   description      = try(var.truemark_observability.kubePrometheusStack.description, "A Helm chart to deploy kube-prometheus-stack")
#   namespace        = try(var.truemark_observability.kubePrometheusStack.namespace, "observability")
#   create_namespace = try(var.truemark_observability.kubePrometheusStack.create_namespace, true)
#   chart            = try(var.truemark_observability.kubePrometheusStack.chart, "kube-prometheus-stack")
#   chart_version    = try(var.truemark_observability.kubePrometheusStack.chart_version, "66.2.1")
#   repository       = try(var.truemark_observability.kubePrometheusStack.repository, "https://prometheus-community.github.io/helm-charts")
#
#   skip_crds = try(var.truemark_observability.kubePrometheusStack.skip_crds, false)
#
#   create_role          = try(var.truemark_observability.kubePrometheusStack.create_role, true)
#   set_irsa_names       = ["serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"]
#   role_name            = try(var.truemark_observability.kubePrometheusStack.role_name, "truemark-observability-kube-prometheus-stack")
#   role_name_use_prefix = try(var.truemark_observability.kubePrometheusStack.role_name_use_prefix, true)
#   role_policies        = lookup(var.truemark_observability.kubePrometheusStack, "role_policies", {})
#   assume_role_condition_test = "StringLike"
#   source_policy_documents = data.aws_iam_policy_document.thanos_iam_role_policy[*].json
#   policy_statements       = lookup(var.truemark_observability.kubePrometheusStack, "policy_statements", [])
#   policy_name             = try(var.truemark_observability.kubePrometheusStack.policy_name, null)
#   policy_name_use_prefix  = try(var.truemark_observability.kubePrometheusStack.policy_name_use_prefix, true)
#   policy_path             = try(var.truemark_observability.kubePrometheusStack.policy_path, null)
#   policy_description      = try(var.truemark_observability.kubePrometheusStack.policy_description, "IAM Policy for kube-promethus-stack")
#
#   oidc_providers = {
#     this = {
#       provider_arn = var.oidc_provider_arn
#       service_account = local.kube_prometheus_stack_service_account
#     }
#   }
#
#   tags       = var.tags
# }

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

  create_role          = try(var.truemark_observability.thanos.create_role, true)
  set_irsa_names       = ["serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"]
  role_name            = try(var.truemark_observability.thanos.role_name, "truemark-observability-thanos")
  role_name_use_prefix = try(var.truemark_observability.thanos.role_name_use_prefix, true)
  role_policies        = lookup(var.truemark_observability.thanos, "role_policies", {})
  assume_role_condition_test = "StringLike"
  source_policy_documents = data.aws_iam_policy_document.thanos_iam_role_policy[*].json
  policy_statements       = lookup(var.truemark_observability.thanos, "policy_statements", [])
  policy_name             = try(var.truemark_observability.thanos.policy_name, null)
  policy_name_use_prefix  = try(var.truemark_observability.thanos.policy_name_use_prefix, true)
  policy_path             = try(var.truemark_observability.thanos.policy_path, null)
  policy_description      = try(var.truemark_observability.thanos.policy_description, "IAM Policy for AWS Load Balancer Controller")

  oidc_providers = {
    this = {
      provider_arn = var.oidc_provider_arn
      service_account = local.thanos_service_account
    }
  }

  tags       = var.tags
}