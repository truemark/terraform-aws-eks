locals {
  tags = merge(var.tags,
    {
      cluster_name = var.addons_context.cluster_name
      managedBy    = "terraform"
    }
  )
  velero_name                    = "velero"
  velero_backup_s3_bucket_arn    = module.velero_backup_s3_bucket.s3_bucket_arn
  velero_backup_s3_bucket_name   = module.velero_backup_s3_bucket.s3_bucket_id
  velero_backup_s3_bucket_prefix = "backups-${var.addons_context.cluster_name}"
}

## S3 Bucket for Velero backups
module "velero_backup_s3_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 3.0"

  create_bucket = true

  bucket_prefix = "${var.addons_context.aws_account_id}-${local.velero_name}-"

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

# https://github.com/vmware-tanzu/velero-plugin-for-aws#option-1-set-permissions-with-an-iam-user
data "aws_iam_policy_document" "velero" {

  statement {
    actions = [
      "ec2:CreateSnapshot",
      "ec2:CreateSnapshots",
      "ec2:CreateTags",
      "ec2:CreateVolume",
      "ec2:DeleteSnapshot"
    ]
    resources = [
      "arn:${var.addons_context.aws_partition}:ec2:${var.addons_context.aws_region}:${var.addons_context.aws_account_id}:instance/*",
      "arn:${var.addons_context.aws_partition}:ec2:${var.addons_context.aws_region}::snapshot/*",
      "arn:${var.addons_context.aws_partition}:ec2:${var.addons_context.aws_region}:${var.addons_context.aws_account_id}:volume/*"
    ]
  }

  statement {
    actions = [
      "ec2:DescribeSnapshots",
      "ec2:DescribeVolumes"
    ]
    resources = ["*"]
  }

  statement {
    actions = [
      "s3:AbortMultipartUpload",
      "s3:DeleteObject",
      "s3:GetObject",
      "s3:ListMultipartUploadParts",
      "s3:PutObject",
    ]
    resources = ["${local.velero_backup_s3_bucket_arn}/*"]
  }

  statement {
    actions   = ["s3:ListBucket"]
    resources = [local.velero_backup_s3_bucket_arn]
  }
}

module "velero_irsa_policy" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "~> 5"

  name_prefix = "velero-"
  path        = "/"

  policy = data.aws_iam_policy_document.velero.json

}

module "velero_irsa_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5"

  role_name_prefix = "velero-"
  role_policy_arns = {
    velero = module.velero_irsa_policy.arn
  }

  oidc_providers = {
    eks = {
      provider_arn               = var.addons_context.oidc_provider_arn
      namespace_service_accounts = ["velero:velero-server"]
    }
  }

  tags = local.tags
}
