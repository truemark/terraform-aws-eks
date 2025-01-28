variable "addons" {
  description = "Kubernetes addons"
  type = object({
    enable_aws_load_balancer_controller = optional(bool, true)
    enable_metrics_server               = optional(bool, true)
    enable_cert_manager                 = optional(bool, false)
    enable_external_dns                 = optional(bool, false)
    enable_istio                        = optional(bool, false)
    enable_istio_ingress                = optional(bool, false)
    enable_external_secrets             = optional(bool, false)
    enable_keda                         = optional(bool, false)
    enable_aws_ebs_csi_resources        = optional(bool, false)
    enable_velero                       = optional(bool, false)
    enable_observability                = optional(bool, false)
  })
  default = {
    enable_aws_load_balancer_controller = true
    enable_metrics_server               = true
  }
  validation {
    condition = alltrue([
      for key in keys(var.addons) : contains([
        "enable_cert_manager",
        "enable_external_dns",
        "enable_istio",
        "enable_istio_ingress",
        "enable_external_secrets",
        "enable_metrics_server",
        "enable_keda",
        "enable_aws_load_balancer_controller",
        "enable_aws_ebs_csi_resources",
        "enable_velero",
        "enable_observability",
        "enable_cast_ai"
      ], key)
    ])
    error_message = "Invalid key in var.addons"
  }
  validation {
    condition = alltrue([
      for key in keys(var.addons) : !contains([
        "enable_karpenter",
        "enable_auto_mode"
      ], key)
    ])
    error_message = "The enable_karpenter params have been moved to compute_mode variable."
  }
}


variable "deploy_addons" {
  description = "Flag to enable or disable the add-ons module. User for staged deployments due to kube_manifest provider limitations."
  type        = bool
  default     = true
}


## Locals
locals {
  addons = {
    enable_cert_manager                 = try(var.addons.enable_cert_manager, false)
    enable_external_dns                 = try(var.addons.enable_external_dns, false)
    enable_istio                        = try(var.addons.enable_istio, false)
    enable_istio_ingress                = try(var.addons.enable_istio_ingress, false)
    enable_external_secrets             = try(var.addons.enable_external_secrets, false)
    enable_metrics_server               = try(var.addons.enable_metrics_server, false)
    enable_keda                         = try(var.addons.enable_keda, false)
    enable_aws_load_balancer_controller = try(var.addons.enable_aws_load_balancer_controller, true)
    enable_aws_ebs_csi_resources        = try(var.addons.enable_aws_ebs_csi_resources, true)
    enable_velero                       = try(var.addons.enable_velero, false)
    enable_observability                = try(var.addons.enable_observability, false)
    enable_cast_ai                      = try(var.addons.enable_cast_ai, false)
    enable_karpenter                    = var.compute_mode == "karpenter" ? true : false
    enable_auto_mode                    = var.compute_mode == "eks_auto_mode" ? true : false
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
    auto_mode                    = var.addons_target_revision
    cast_ai = {
      agent              = "0.86.0"
      cluster_controller = "0.74.4"
      spot_handler       = "0.22.1"
    }
  }

  auto_mode_system_nodepool_manifest = try(module.addons.gitops_metadata.auto_mode_system_nodepool_manifest, null)
  addons_metadata = merge(
    # module.addons.gitops_metadata
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

  argocd_apps = merge({
    eks-addons = {
      project              = "default"
      repo_url             = var.addons_repo_url
      target_revision      = var.addons_target_revision
      addons_repo_revision = var.addons_target_revision
      path                 = var.addons_repo_path
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
        auto_mode = {
          enabled                   = local.addons.enable_auto_mode
          nodeIamRoleName           = try(module.addons.gitops_metadata.auto_mode_iam_role_name, null)
          values                    = try(yamldecode(join("\n", var.auto_mode_helm_config.values)), {})
          chartVersion              = try(var.auto_mode_helm_config.chart_version, local.addons_default_versions.auto_mode)
          truemarkNodeClassDefaults = try(var.auto_mode_helm_config.truemark_nodeclass_default, {})
          truemarkNodePoolDefaults  = try(var.auto_mode_helm_config.truemark_node_pool_default, {})
          clusterName               = module.eks.cluster_name
          target_revision           = var.addons_target_revision
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
          interruptionQueue         = try(module.addons.gitops_metadata.karpenter_interruption_queue, null)
          nodeIamRoleName           = try(module.addons.gitops_metadata.karpenter_node_iam_role_arn, null)
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
        }
        awsCsiEbsResources = {
          addons_repo_revision = var.addons_target_revision
          enabled              = local.addons.enable_aws_ebs_csi_resources
          csidriver            = local.addons.enable_auto_mode ? "ebs.csi.eks.amazonaws.com" : "ebs.csi.aws.com"
        istio = {
          chartVersion = try(var.istio_helm_config.chart_version, local.addons_default_versions.istio)
          values       = try(yamldecode(join("\n", var.istio_helm_config.values)), {})
          base = merge({
            enabled = local.addons.enable_istio
          }, try(var.istio_helm_config.base, {}))
          ingress_enabled = var.istio_helm_config.ingress_enabled
          ingress         = var.istio_helm_config.ingress
        }
        velero = {
          enabled            = local.addons.enable_velero
          iamRoleArn         = try(module.addons.gitops_metadata.velero_iam_role_arn, "")
          values             = try(yamldecode(join("\n", var.velero_helm_config.values)), {})
          bucket             = try(module.addons.gitops_metadata.velero_backup_s3_bucket_name, null)
          prefix             = try(module.addons.gitops_metadata.velero_backup_s3_bucket_prefix, null)
          serviceAccountName = try(module.addons.gitops_metadata.velero_service_account_name, null)
          region             = data.aws_region.current.id
          chartVersion       = try(var.velero_helm_config.chart_version, "8.0.0")
        }
        castAi = {
          enabled   = local.addons.enable_cast_ai
          clusterId = var.cluster_name
          apiKey    = try(var.castai_helm_config.api_key, "cast-ai")
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
        local.addons.enable_observability && var.deploy_addons ? { observability = {
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
  }, try(var.workloads_argocd_apps, {}))
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
    chart_version = "7.7.10"
    values = [
      <<-EOT
    global:
      affinity:
        ${jsonencode(var.critical_addons_node_affinity)}
      tolerations:
        ${jsonencode(var.critical_addons_node_tolerations)}
    configs:
      params:
        server.insecure: true
    EOT
    ]
  }
  apps = local.argocd_apps
  depends_on = [
    aws_eks_access_entry.access_entries,
    aws_eks_access_policy_association.access_policy_associations,
  ]
}

################################################################################
# EKS Blueprints Addons
################################################################################
module "addons" {
  deploy_addons = var.deploy_addons
  source        = "./modules/addons"
  depends_on = [
    aws_eks_access_entry.access_entries,
    aws_eks_access_policy_association.access_policy_associations,
  ]

  oidc_provider_arn                  = module.eks.oidc_provider_arn
  aws_region                         = data.aws_region.current.name
  aws_account_id                     = data.aws_caller_identity.current.account_id
  aws_partition                      = local.aws_partition
  cluster_name                       = module.eks.cluster_name
  cluster_endpoint                   = module.eks.cluster_endpoint
  cluster_certificate_authority_data = module.eks.cluster_certificate_authority_data
  cluster_token                      = data.aws_eks_cluster_auth.cluster.token
  cluster_version                    = var.cluster_version
  critical_addons_node_selector      = var.critical_addons_node_selector
  critical_addons_node_affinity      = var.critical_addons_node_affinity
  critical_addons_node_tolerations   = var.critical_addons_node_tolerations
  auto_mode_system_nodes_config      = var.auto_mode_system_nodes_config

  # Using GitOps Bridge
  create_kubernetes_resources = var.enable_gitops_bridge_bootstrap ? false : true

  # Cert Manager
  enable_cert_manager = local.addons.enable_cert_manager

  # External DNS
  enable_external_dns = local.addons.enable_external_dns

  # Karpenter
  enable_karpenter = local.addons.enable_karpenter

  # Auto-mode
  vpc_id                    = var.vpc_id
  enable_auto_mode          = local.addons.enable_auto_mode
  cluster_security_group_id = module.eks.cluster_security_group_id
  node_security_group_id    = module.eks.node_security_group_id

  # External Secrets
  enable_external_secrets = local.addons.enable_external_secrets

  # Metrics Server
  enable_metrics_server = local.addons.enable_metrics_server

  # Keda
  enable_keda = local.addons.enable_keda

  # Load Balancer Controller
  enable_aws_load_balancer_controller = local.addons.enable_aws_load_balancer_controller

  # Velero
  enable_velero = local.addons.enable_velero

  # Truemark Observability
  enable_observability = local.addons.enable_observability

  # AWS EBS CSI Resources
  enable_aws_ebs_csi_resources = local.addons.enable_aws_ebs_csi_resources
}
