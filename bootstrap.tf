variable "addons" {
  description = "Kubernetes addons"
  type        = any
  default = {
    enable_aws_load_balancer_controller = true
    enable_metrics_server               = true
  }
}

## Locals

locals {
  addons = {
    enable_cert_manager                 = try(var.addons.enable_cert_manager, true)
    enable_external_dns                 = try(var.addons.enable_external_dns, true)
    enable_istio                        = try(var.addons.enable_istio, true)
    enable_istio_ingress                = try(var.addons.enable_istio_ingress, true)
    enable_karpenter                    = try(var.addons.enable_karpenter, true)
    enable_external_secrets             = try(var.addons.enable_external_secrets, true)
    enable_metrics_server               = try(var.addons.enable_metrics_server, true)
    enable_keda                         = try(var.addons.enable_keda, true)
    enable_aws_load_balancer_controller = try(var.addons.enable_aws_load_balancer_controller, true)
    enable_aws_ebs_csi_resources        = try(var.addons.enable_aws_ebs_csi_resources, true)
    enable_velero                       = try(var.addons.enable_velero, true)
    enable_observability                = try(var.addons.enable_observability, true)
    enable_cast_ai                      = try(var.addons.enable_cast_ai, false)
  }

  addons_default_versions = {
    cert_manager                 = "v1.14.3"
    external_dns                 = "1.15.0"
    karpenter                    = "1.0.7"
    external_secrets             = "0.7.0"
    metrics_server               = "3.12.0"
    keda                         = "2.16.0"
    aws_load_balancer_controller = "1.10.0"
    istio                        = "1.23.3"
    cast_ai = {
      agent              = "0.86.0"
      cluster_controller = "0.74.4"
      spot_handler       = "0.22.1"
    }
  }

  addons_metadata = merge(
    #     module.addons.gitops_metadata,
    {
      aws_cluster_name = module.eks.cluster_name
      aws_region       = data.aws_region.current.name
      aws_account_id   = data.aws_caller_identity.current.account_id
      aws_vpc_id       = var.vpc_id
    }
  )

  tags = {
    Blueprint = var.cluster_name
  }

  argocd_apps = {
    eks-addons = {
      project         = "default"
      repo_url        = "https://github.com/truemark/terraform-aws-eks"
      target_revision = "feat/argocd"
      path            = "bootstrap/charts/eks-addons"
      values = merge({
        certManager = {
          enabled      = local.addons.enable_cert_manager
          iamRoleArn   = try(module.addons.gitops_metadata.cert_manager_iam_role_arn, "")
          values       = try(yamldecode(join("\n", var.cert_manager_helm_config.values)), {})
          chartVersion = try(var.cert_manager_helm_config.chart_version, local.addons_default_versions.cert_manager)
        }
        externalDNS = {
          enabled      = local.addons.enable_external_dns
          iamRoleArn   = try(module.addons.gitops_metadata.external_dns_iam_role_arn, "")
          values       = try(yamldecode(join("\n", var.external_dns_helm_config.values)), {})
          chartVersion = try(var.external_dns_helm_config.chart_version, local.addons_default_versions.external_dns)
        }
        karpenter = {
          enabled                   = local.addons.enable_karpenter
          iamRoleArn                = try(module.addons.gitops_metadata.karpenter_iam_role_arn, "")
          values                    = try(yamldecode(join("\n", var.karpenter_helm_config.values)), {})
          chartVersion              = try(var.karpenter_helm_config.chart_version, local.addons_default_versions.karpenter)
          enableCrdWebhookConfig    = try(var.karpenter_helm_config.enable_karpenter_crd_webhook, false)
          truemarkNodeClassDefaults = try(var.karpenter_helm_config.truemark_nodeclass_default, {})
          truemarkNodePoolDefaults  = try(var.karpenter_helm_config.truemark_node_pool_default, {})
          clusterName               = module.eks.cluster_name
          clusterEndpoint           = module.eks.cluster_endpoint
          interruptionQueue         = module.addons.gitops_metadata.karpenter_interruption_queue
          nodeIamRoleName           = module.addons.gitops_metadata.karpenter_node_iam_role_arn
        }
        externalSecrets = {
          enabled      = local.addons.enable_external_secrets
          iamRoleArn   = try(module.addons.gitops_metadata.external_secrets_iam_role_arn, "")
          values       = try(yamldecode(join("\n", var.external_secrets_helm_config.values)), {})
          chartVersion = try(var.external_secrets_helm_config.chart_version, local.addons_default_versions.external_secrets)
        }
        metricsServer = {
          enabled      = local.addons.enable_metrics_server
          values       = try(yamldecode(join("\n", var.metrics_server_helm_config.values)), {})
          chartVersion = try(var.metrics_server_helm_config.chart_version, local.addons_default_versions.metrics_server)
        }
        keda = {
          enabled      = local.addons.enable_keda
          iamRoleArn   = try(module.addons.gitops_metadata.keda_iam_role_arn, "")
          values       = try(yamldecode(join("\n", var.keda_helm_config.values)), {})
          chartVersion = try(var.keda_helm_config.chart_version, local.addons_default_versions.keda)
        }
        loadBalancerController = {
          enabled      = local.addons.enable_aws_load_balancer_controller
          iamRoleArn   = try(module.addons.gitops_metadata.aws_load_balancer_controller_iam_role_arn, "")
          values       = try(yamldecode(join("\n", var.aws_load_balancer_controller_helm_config.values)), {})
          clusterName  = module.eks.cluster_name
          chartVersion = try(var.aws_load_balancer_controller_helm_config.chart_version, local.addons_default_versions.aws_load_balancer_controller)
          vpcId        = var.vpc_id
          serviceAccount = {
            name = module.addons.gitops_metadata.aws_load_balancer_controller_service_account_name
          }
        }
        awsCsiEbsResources = {
          enabled = local.addons.enable_aws_ebs_csi_resources
        }
        istio = {
          chartVersion = try(var.istio_helm_config.chart_version, local.addons_default_versions.istio)
          values       = try(yamldecode(join("\n", var.istio_helm_config.values)), {})
          base = {
            enabled = local.addons.enable_istio
          }
          ingress_enabled = var.istio_helm_config.ingress_enabled
          ingress         = var.istio_helm_config.ingress
        }
        velero = {
          enabled            = local.addons.enable_velero
          iamRoleArn         = try(module.addons.gitops_metadata.velero_iam_role_arn, "")
          values             = try(yamldecode(join("\n", var.velero_helm_config.values)), {})
          bucket             = module.addons.gitops_metadata.velero_backup_s3_bucket_name
          prefix             = module.addons.gitops_metadata.velero_backup_s3_bucket_prefix
          serviceAccountName = module.addons.gitops_metadata.velero_service_account_name
          region             = data.aws_region.current.id
          chartVersion       = try(var.velero_helm_config.chart_version, "8.0.0")
        }
        castAi = {
          enabled   = local.addons.enable_cast_ai
          clusterId = var.cluster_name
          apiKey    = var.castai_helm_config.api_key
          agent = {
            chartVersion = try(var.castai_helm_config.agent.chart_version, local.addons_default_versions.cast_ai.agent)
            values       = try(yamldecode(join("\n", var.castai_helm_config.agent.values)), {})
          }
          clusterController = {
            chartVersion = try(var.castai_helm_config.cluster_controller.chart_version, local.addons_default_versions.cast_ai.cluster_controller)
            values       = try(yamldecode(join("\n", var.castai_helm_config.cluster_controller.values)), {})
          }
          spotHandler = {
            chartVersion = try(var.castai_helm_config.spot_handler.chart_version, local.addons_default_versions.cast_ai.spot_handler)
            values       = try(yamldecode(join("\n", var.castai_helm_config.spot_handler.values)), {})
          }
        }
        },
        local.addons.enable_observability ? { observability = {
          enabled = local.addons.enable_observability
          values  = try(yamldecode(join("\n", var.observability_helm_config.values)), {})
          region  = data.aws_region.current.id
          thanos = {
            enabled      = var.observability_helm_config.thanos.enabled
            s3BucketName = module.addons.gitops_metadata.observability_thanos_s3_bucket_name
            iamRoleArn   = module.addons.gitops_metadata.observability_thanos_iam_role_arn
          }
          kubePrometheusStack = {
            enabled = try(var.observability_helm_config.kube_prometheus_stack.enabled, true)
            values  = try(yamldecode(join("\n", var.observability_helm_config.kube_prometheus_stack.values)), {})
            prometheus = merge({
              iamRoleArn = module.addons.gitops_metadata.observability_prometheus_iam_role_arn
            }, var.observability_helm_config.kube_prometheus_stack.prometheus)
            alertmanager = {
              alertsTopicArn   = var.observability_helm_config.kube_prometheus_stack.alertmanager.alerts_topic_arn
              alertsSnsSubject = var.observability_helm_config.kube_prometheus_stack.alertmanager.alerts_sns_subject
            }
            grafana = {
              adminPassword = module.addons.gitops_metadata.observability_grafana_admin_password
            }
          }
        } } : {}
      )
    }
  }
}

################################################################################
# GitOps Bridge: Bootstrap
################################################################################
variable "enable_gitops_bridge_bootstrap" {
  default = true
}

module "gitops_bridge_bootstrap" {
  count  = var.enable_gitops_bridge_bootstrap ? 1 : 0
  source = "./modules/argocd-gitops-bridge"

  cluster = {
    metadata = local.addons_metadata
  }
  argocd = {
    chart_version = "7.6.10"
    values = [
      <<-EOT
    global:
      nodeSelector:
        ${jsonencode(var.critical_addons_node_selector)}
      tolerations:
        ${jsonencode(var.critical_addons_node_tolerations)}
    configs:
      params:
        server.insecure: true
    EOT
    ]
  }
  apps = local.argocd_apps
}

################################################################################
# EKS Blueprints Addons
################################################################################
module "addons" {
  source = "./modules/addons"

  oidc_provider_arn                = module.eks.oidc_provider_arn
  aws_region                       = data.aws_region.current.name
  aws_account_id                   = data.aws_caller_identity.current.account_id
  aws_partition                    = data.aws_partition.current.partition
  cluster_name                     = module.eks.cluster_name
  cluster_endpoint                 = module.eks.cluster_endpoint
  cluster_version                  = var.cluster_version
  critical_addons_node_selector    = var.critical_addons_node_selector
  critical_addons_node_tolerations = var.critical_addons_node_tolerations


  # Using GitOps Bridge
  create_kubernetes_resources = var.enable_gitops_bridge_bootstrap ? false : true

  # Cert Manager
  enable_cert_manager = local.addons.enable_cert_manager
  cert_manager        = var.cert_manager_helm_config

  # External DNS
  enable_external_dns            = local.addons.enable_external_dns
  external_dns                   = var.external_dns_helm_config
  external_dns_route53_zone_arns = try(var.external_dns_helm_config.route53_zone_arns, [])

  # Karpenter
  enable_karpenter = local.addons.enable_karpenter
  karpenter        = var.karpenter_helm_config

  # External Secrets
  enable_external_secrets = local.addons.enable_external_secrets
  external_secrets        = var.external_secrets_helm_config

  # Metrics Server
  enable_metrics_server = local.addons.enable_metrics_server
  metrics_server        = var.metrics_server_helm_config

  # Keda
  enable_keda = local.addons.enable_keda
  keda        = var.keda_helm_config

  # Load Balancer Controller
  enable_aws_load_balancer_controller = local.addons.enable_aws_load_balancer_controller
  aws_load_balancer_controller        = var.aws_load_balancer_controller_helm_config

  # Velero
  enable_velero = local.addons.enable_velero
  velero        = var.velero_helm_config

  # Truemark Observability
  enable_observability = local.addons.enable_observability
  observability        = var.observability_helm_config

  # AWS EBS CSI Resources
  enable_aws_ebs_csi_resources = local.addons.enable_aws_ebs_csi_resources
  #   tags = local.tags
}

