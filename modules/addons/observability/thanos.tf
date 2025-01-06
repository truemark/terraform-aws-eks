## Thanos
module "thanos_s3_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 3.0"

  create_bucket = true

  bucket_prefix = "${var.addons_context.aws_account_id}-${local.thanos_name}-"

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

module "thanos_iam_role" {
  source           = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version          = "5.48.0"
  role_name_prefix = "thanos-"
  oidc_providers = {
    this = {
      provider_arn               = var.addons_context.oidc_provider_arn
      namespace_service_accounts = ["observability:${local.thanos_service_account}"]
      assume_role_condition_test = "StringLike"
    }
  }
  role_policy_arns = {
    bucket = module.prometheus_iam_policy.arn
  }
}
