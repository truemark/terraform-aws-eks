output "gitops_metadata" {
  value = { for k, v in {
    iam_role_arn            = module.velero_irsa_role.iam_role_arn
    backup_s3_bucket_arn    = local.velero_backup_s3_bucket_arn
    backup_s3_bucket_name   = local.velero_backup_s3_bucket_name
    backup_s3_bucket_prefix = local.velero_backup_s3_bucket_prefix
    } : "velero_${k}" => v
  }
}
