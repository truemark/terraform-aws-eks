locals {
  tags = merge(var.tags,
    {
      cluster_name = var.addons_context.cluster_name
      managedBy    = "terraform"
    }
  )
}

################################################################################
# IAM Role for keda
################################################################################
data "aws_iam_policy_document" "keda" {
  statement {
    actions   = ["cloudwatch:GetMetricData", "cloudwatch:ListMetrics"]
    resources = ["*"]
  }
}

module "keda_irsa_policy" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "~> 5"

  name_prefix = "keda-"
  path        = "/"

  policy = data.aws_iam_policy_document.keda.json

}


module "keda_irsa_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5"

  role_name_prefix = "keda-"
  role_policy_arns = {
    keda = module.keda_irsa_policy.arn
  }

  oidc_providers = {
    eks = {
      provider_arn               = var.addons_context.oidc_provider_arn
      namespace_service_accounts = ["keda:keda"]
    }
  }

  tags = local.tags
}



