locals {
  policy_name             = "${var.addons_context.cluster_name}-kube-bench-security-hub"
  enable_aws_security_hub = try(var.kube_bench_helm_config.enable_security_hub_reports, false)
  tags = merge(var.tags,
    {
      cluster_name = var.addons_context.cluster_name
    }
  )
}

# IAM role for Security Hub access
module "kube_bench_irsa_role" {
  source           = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version          = "~> 5"
  role_name_prefix = "kube-bench-"
  oidc_providers = {
    eks = {
      provider_arn               = var.addons_context.oidc_provider_arn
      namespace_service_accounts = ["kube-system:kube-bench"]
    }
  }
  role_policy_arns = {
  }
  tags = local.tags
}

resource "aws_iam_policy_attachment" "kube-bench-security-hub-policy" {
  count      = local.enable_aws_security_hub ? 1 : 0
  name       = local.policy_name
  roles      = [module.kube_bench_irsa_role.iam_role_name]
  policy_arn = aws_iam_policy.security_hub_policy[0].arn
}

# IAM policy for Security Hub access
resource "aws_iam_policy" "security_hub_policy" {
  count = local.enable_aws_security_hub ? 1 : 0
  name  = local.policy_name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        "Effect" : "Allow",
        "Action" : "securityhub:BatchImportFindings",
        "Resource" : [
          "arn:aws:securityhub:${var.addons_context.aws_region}::product/aqua-security/kube-bench"
        ]
      }
    ]
  })
}

resource "aws_securityhub_product_subscription" "kube-bench" {
  count       = local.enable_aws_security_hub ? 1 : 0
  product_arn = "arn:aws:securityhub:${var.addons_context.aws_region}::product/aqua-security/kube-bench"
}
