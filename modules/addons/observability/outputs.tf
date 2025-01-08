output "gitops_metadata" {
  value = { for k, v in {
    thanos_iam_role_arn     = module.thanos_iam_role.iam_role_arn
    thanos_s3_bucket_name   = module.thanos_s3_bucket.s3_bucket_id
    prometheus_iam_role_arn = module.prometheus_iam_role.iam_role_arn
    grafana_admin_password  = random_password.grafana_admin_password.result
    } : "observability_${k}" => v
  }
}
