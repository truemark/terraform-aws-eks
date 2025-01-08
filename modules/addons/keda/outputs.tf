output "gitops_metadata" {
  value = { for k, v in {
    iam_role_arn = module.keda_irsa_role.iam_role_arn
    } : "keda_${k}" => v
  }
}
