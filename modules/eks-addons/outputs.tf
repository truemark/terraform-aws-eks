output "gitops_metadata" {
  description = "GitOps Bridge metadata"
  value = merge(
    { for k, v in {
      iam_role_arn    = module.cert_manager.iam_role_arn
      namespace       = local.cert_manager_namespace
      service_account = local.cert_manager_service_account
      } : "cert_manager_${k}" => v if var.enable_cert_manager
    },
    { for k, v in {
      iam_role_arn    = module.external_dns.iam_role_arn
      namespace       = local.external_dns_namespace
      service_account = local.external_dns_service_account
      } : "external_dns_${k}" => v if var.enable_external_dns
    },
    { for k, v in {
      iam_role_arn    = module.external_secrets.iam_role_arn
      namespace       = local.external_secrets_namespace
      service_account = local.external_secrets_service_account
      } : "external_secrets_${k}" => v if var.enable_external_secrets
    },
    { for k, v in {
      namespace = local.metrics_server_namespace
      } : "metrics_server_${k}" => v if var.enable_metrics_server
    },
    { for k, v in {
      iam_role_arn    = module.keda.iam_role_arn
      namespace       = local.keda_namespace
      service_account = local.keda_service_account
      } : "keda_${k}" => v if var.enable_keda
    },
    { for k, v in {
      iam_role_arn       = module.karpenter[0].iam_role_arn
      node_iam_role_arn  = module.karpenter[0].node_iam_role_name
      interruption_queue = module.karpenter[0].queue_name
      namespace          = local.karpenter_namespace
      service_account    = local.karpenter_service_account
      } : "karpenter_${k}" => v if var.enable_karpenter
    }
  )
}
