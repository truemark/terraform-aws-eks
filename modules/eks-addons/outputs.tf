output "gitops_metadata" {
  description = "GitOps Bridge metadata"
  value = merge(
    { for k, v in {
      iam_role_arn    = module.cert_manager.iam_role_arn
      namespace       = local.cert_manager_namespace
      service_account = local.cert_manager_service_account
      } : "cert_manager_${k}" => v if var.enable_cert_manager
    }
  )
}