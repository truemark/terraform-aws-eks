output "gitops_metadata" {
  description = "GitOps Bridge metadata"
  value = merge(
    { for k, v in {
      iam_role_arn         = module.cert_manager.iam_role_arn
      namespace            = local.cert_manager_namespace
      service_account_name = local.cert_manager_service_account
      } : "cert_manager_${k}" => v if var.enable_cert_manager
    },
    { for k, v in {
      iam_role_arn         = module.external_dns.iam_role_arn
      namespace            = local.external_dns_namespace
      service_account_name = local.external_dns_service_account
      } : "external_dns_${k}" => v if var.enable_external_dns
    },
    { for k, v in {
      iam_role_arn         = module.external_secrets.iam_role_arn
      namespace            = local.external_secrets_namespace
      service_account_name = local.external_secrets_service_account
      } : "external_secrets_${k}" => v if var.enable_external_secrets
    },
    { for k, v in {
      namespace = local.metrics_server_namespace
      } : "metrics_server_${k}" => v if var.enable_metrics_server
    },
    { for k, v in {
      iam_role_arn         = module.keda.iam_role_arn
      namespace            = local.keda_namespace
      service_account_name = local.keda_service_account
      } : "keda_${k}" => v if var.enable_keda
    },
    { for k, v in {
      iam_role_arn         = module.aws_load_balancer_controller.iam_role_arn
      namespace            = local.aws_load_balancer_controller_namespace
      service_account_name = local.aws_load_balancer_controller_service_account_name
      } : "aws_load_balancer_controller_${k}" => v if var.enable_aws_load_balancer_controller
    },
    { for k, v in {
      iam_role_arn         = module.karpenter[0].iam_role_arn
      node_iam_role_arn    = module.karpenter[0].node_iam_role_name
      interruption_queue   = module.karpenter[0].queue_name
      namespace            = local.karpenter_namespace
      service_account_name = local.karpenter_service_account
      } : "karpenter_${k}" => v if var.enable_karpenter
    },
    { for k, v in {
      iam_role_arn            = module.velero.iam_role_arn
      namespace               = local.velero_namespace
      backup_s3_bucket_arn    = local.velero_backup_s3_bucket_arn
      backup_s3_bucket_name   = local.velero_backup_s3_bucket_name
      backup_s3_bucket_prefix = local.velero_backup_s3_bucket_prefix
      service_account_name    = local.velero_service_account
      } : "velero_${k}" => v if var.enable_velero
    },
    { for k, v in {
      thanos_iam_role_arn     = var.observability.thanos.enabled ? module.thanos.iam_role_arn : ""
      thanos_s3_bucket_name   = var.observability.thanos.enabled ? module.thanos_s3_bucket.s3_bucket_id : ""
      prometheus_iam_role_arn = var.observability.kube_prometheus_stack.enabled ? module.prometheus_iam_role[*].iam_role_arn : ""
      grafana_admin_password  = random_password.grafana_admin_password.result
      } : "observability_${k}" => v if var.enable_observability
    }
  )
}
