output "gitops_metadata" {
  value = { for k, v in {
    iam_role_arn  = module.kube_bench_irsa_role.iam_role_arn
    iam_role_name = module.kube_bench_irsa_role.iam_role_name
    } : "kube_bench_${k}" => v
  }
}
