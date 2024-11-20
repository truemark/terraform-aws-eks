################################################################################
# Velero
################################################################################\

variable "enable_velero" {
  description = "Enable Kubernetes Dashboard add-on"
  type        = bool
  default     = false
}

variable "velero" {
  description = "Velero add-on configuration values"
  type        = any
  default     = {}
}

locals {
  velero_name                    = "velero"
  velero_service_account         = try(var.velero.service_account_name, "${local.velero_name}-server")
  velero_backup_s3_bucket_arn    = try(var.velero.velero_backup_s3_bucket_arn, module.velero_backup_s3_bucket.s3_bucket_arn)
  velero_backup_s3_bucket_name   = try(var.velero.velero_backup_s3_bucket_name, module.velero_backup_s3_bucket.s3_bucket_id)
  velero_backup_s3_bucket_prefix = try(var.velero.velero_backup_s3_bucket_prefix, "backups-${var.cluster_name}")
  velero_namespace               = try(var.velero.namespace, "velero")
}

## S3 Bucket for Velero backups
module "velero_backup_s3_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 3.0"

  create_bucket = try(var.enable_velero, false)

  bucket_prefix = "${var.aws_account_id}-${local.velero_name}-"

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
  count = var.enable_velero ? 1 : 0

  source_policy_documents   = lookup(var.velero, "source_policy_documents", [])
  override_policy_documents = lookup(var.velero, "override_policy_documents", [])

  statement {
    actions = [
      "ec2:CreateSnapshot",
      "ec2:CreateSnapshots",
      "ec2:CreateTags",
      "ec2:CreateVolume",
      "ec2:DeleteSnapshot"
    ]
    resources = [
      "arn:${var.aws_partition}:ec2:${var.aws_region}:${var.aws_account_id}:instance/*",
      "arn:${var.aws_partition}:ec2:${var.aws_region}::snapshot/*",
      "arn:${var.aws_partition}:ec2:${var.aws_region}:${var.aws_account_id}:volume/*"
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

module "velero" {
  source  = "aws-ia/eks-blueprints-addon/aws"
  version = "1.1.1"

  create = var.enable_velero

  # Disable helm release
  create_release = var.create_kubernetes_resources

  # https://github.com/vmware-tanzu/helm-charts/blob/main/charts/velero/Chart.yaml
  name             = try(var.velero.name, "velero")
  description      = try(var.velero.description, "A Helm chart to install the Velero")
  namespace        = local.velero_namespace
  create_namespace = try(var.velero.create_namespace, true)
  chart            = try(var.velero.chart, "velero")
  chart_version    = try(var.velero.chart_version, "8.0.0")
  repository       = try(var.velero.repository, "https://vmware-tanzu.github.io/helm-charts/")
  values           = try(var.velero.values, [])

  wait = try(var.velero.wait, false)

  postrender = try(var.velero.postrender, [])
  set = concat([
    {
      name  = "initContainers"
      value = <<-EOT
        - name: velero-plugin-for-aws
          image: velero/velero-plugin-for-aws:v1.7.1
          imagePullPolicy: IfNotPresent
          volumeMounts:
            - mountPath: /target
              name: plugins
      EOT
    },
    {
      name  = "serviceAccount.server.name"
      value = local.velero_service_account
    },
    {
      name  = "configuration.backupStorageLocation[0].name"
      value = "aws-s3"
    },
    {
      name  = "configuration.backupStorageLocation[0].provider"
      value = "aws"
    },
    {
      name  = "configuration.backupStorageLocation[0].prefix"
      value = local.velero_backup_s3_bucket_prefix
    },
    {
      name  = "configuration.backupStorageLocation[0].bucket"
      value = local.velero_backup_s3_bucket_name
    },
    {
      name  = "configuration.backupStorageLocation[0].config.region"
      value = var.aws_region
    },
    {
      name  = "configuration.volumeSnapshotLocation[0].name"
      value = "aws-snapshot"
    },
    {
      name  = "configuration.volumeSnapshotLocation[0].provider"
      value = "aws"
    },
    {
      name  = "configuration.volumeSnapshotLocation[0].config.region"
      value = var.aws_region
    },
    {
      name  = "credentials.useSecret"
      value = false
    }],
    try(var.velero.set, [])
  )
  set_sensitive = try(var.velero.set_sensitive, [])

  # IAM role for service account (IRSA)
  set_irsa_names       = ["serviceAccount.server.annotations.eks\\.amazonaws\\.com/role-arn"]
  create_role          = try(var.velero.create_role, true)
  role_name            = try(var.velero.role_name, "velero")
  role_name_use_prefix = try(var.velero.role_name_use_prefix, true)
  role_path            = try(var.velero.role_path, "/")
  role_description     = try(var.velero.role_description, "IRSA for Velero")
  role_policies        = lookup(var.velero, "role_policies", {})

  source_policy_documents = data.aws_iam_policy_document.velero[*].json
  policy_statements       = lookup(var.velero, "policy_statements", [])
  policy_name             = try(var.velero.policy_name, "velero")
  policy_name_use_prefix  = try(var.velero.policy_name_use_prefix, true)
  policy_description      = try(var.velero.policy_description, "IAM Policy for Velero")

  oidc_providers = {
    controller = {
      provider_arn = var.oidc_provider_arn
      # namespace is inherited from chart
      service_account = local.velero_service_account
    }
  }

  tags = var.tags
}
