locals {
  tags = merge(var.tags,
    {
      cluster_name = var.addons_context.cluster_name
      managedBy    = "terraform"
    }
  )
}

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
  dynamic "statement" {
    for_each = var.observability_helm_config.kube_prometheus_stack.alertmanager.alerts_topic_arn != "" ? [1] : []
    content {
      actions = [
        "sns:*"
      ]
      resources = [var.observability_helm_config.kube_prometheus_stack.alertmanager.alerts_topic_arn]
    }
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
  name_prefix = "prometheus-"
  policy  = data.aws_iam_policy_document.prometheus_iam_role_policy.json
}

module "prometheus_iam_role" {
  source           = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version          = "5.48.0"
  role_name_prefix = "prometheus-"
  oidc_providers = {
    this = {
      provider_arn               = var.addons_context.oidc_provider_arn
      namespace_service_accounts = ["observability:${local.prometheus_service_account}", "observability:k8s-observabilility-alertmanager"]
    }
  }
  role_policy_arns = {
    prometheus = module.prometheus_iam_policy.arn
  }
}

## Grafana
resource "random_password" "grafana_admin_password" {
  length = 12
}

