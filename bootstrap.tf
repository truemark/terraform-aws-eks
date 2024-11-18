variable "addons" {
  description = "Kubernetes addons"
  type        = any
  default = {
    enable_aws_load_balancer_controller = true
    enable_metrics_server               = true
  }
}

# Addons Git
variable "gitops_addons_org" {
  description = "Git repository org/user contains for addons"
  type        = string
  default     = "https://github.com/aws-samples"
}
variable "gitops_addons_repo" {
  description = "Git repository contains for addons"
  type        = string
  default     = "eks-blueprints-add-ons"
}
variable "gitops_addons_revision" {
  description = "Git repository revision/branch/ref for addons"
  type        = string
  default     = "main"
}
variable "gitops_addons_basepath" {
  description = "Git repository base path for addons"
  type        = string
  default     = "argocd/"
}
variable "gitops_addons_path" {
  description = "Git repository path for addons"
  type        = string
  default     = "bootstrap/control-plane/addons"
}

# Workloads Git
variable "gitops_workload_org" {
  description = "Git repository org/user contains for workload"
  type        = string
  default     = "https://github.com/aws-ia"
}
variable "gitops_workload_repo" {
  description = "Git repository contains for workload"
  type        = string
  default     = "terraform-aws-eks-blueprints"
}
variable "gitops_workload_revision" {
  description = "Git repository revision/branch/ref for workload"
  type        = string
  default     = "main"
}
variable "gitops_workload_basepath" {
  description = "Git repository base path for workload"
  type        = string
  default     = "patterns/gitops/"
}
variable "gitops_workload_path" {
  description = "Git repository path for workload"
  type        = string
  default     = "getting-started-argocd/k8s"
}

locals {
  gitops_addons_url      = "${var.gitops_addons_org}/${var.gitops_addons_repo}"
  gitops_addons_basepath = var.gitops_addons_basepath
  gitops_addons_path     = var.gitops_addons_path
  gitops_addons_revision = var.gitops_addons_revision

  gitops_workload_url      = "${var.gitops_workload_org}/${var.gitops_workload_repo}"
  gitops_workload_basepath = var.gitops_workload_basepath
  gitops_workload_path     = var.gitops_workload_path
  gitops_workload_revision = var.gitops_workload_revision

  eks_addons = {
    enable_argocd                       = try(var.addons.enable_argocd, false)
    enable_cert_manager                 = try(var.addons.enable_cert_manager, false)
    enable_external_dns                 = try(var.addons.enable_external_dns, false)
    enable_istio                        = try(var.addons.enable_istio, false)
    enable_istio_ingress                = try(var.addons.enable_istio_ingress, false)
    enable_karpenter                    = try(var.addons.enable_karpenter, false)
    enable_external_secrets             = try(var.addons.enable_external_secrets, false)
    enable_metrics_server               = try(var.addons.enable_metrics_server, false)
    enable_keda                         = try(var.addons.enable_keda, false)
    enable_aws_load_balancer_controller = try(var.addons.enable_aws_load_balancer_controller, false)
    enable_aws_ebs_csi_resources        = try(var.addons.enable_aws_ebs_csi_resources, false)
  }

  addons_metadata = merge(
    #     module.eks_addons.gitops_metadata,
    {
      aws_cluster_name = module.eks.cluster_name
      aws_region       = data.aws_region.current.name
      aws_account_id   = data.aws_caller_identity.current.account_id
      aws_vpc_id       = var.vpc_id
    },
    {
      addons_repo_url      = local.gitops_addons_url
      addons_repo_basepath = local.gitops_addons_basepath
      addons_repo_path     = local.gitops_addons_path
      addons_repo_revision = local.gitops_addons_revision
    },
    {
      workload_repo_url      = local.gitops_workload_url
      workload_repo_basepath = local.gitops_workload_basepath
      workload_repo_path     = local.gitops_workload_path
      workload_repo_revision = local.gitops_workload_revision
    }
  )

  tags = {
    Blueprint  = var.cluster_name
    GithubRepo = "github.com/aws-ia/terraform-aws-eks-blueprints"
  }

  argocd_apps = {
    eks-addons = {
      project         = "default"
      repo_url        = "https://github.com/truemark/terraform-aws-eks"
      target_revision = "feat/argocd"
      path            = "bootstrap/charts/eks-addons"
      values = {
        certManager = {
          enabled      = local.eks_addons.enable_cert_manager,
          iamRoleArn   = module.eks_addons.gitops_metadata.cert_manager_iam_role_arn,
          values       = try(yamldecode(join("\n", var.cert_manager_helm_config.values)), {}),
          chartVersion = try(var.cert_manager_helm_config.chart_version, [])
        }
        externalDNS = {
          enabled      = local.eks_addons.enable_external_dns,
          iamRoleArn   = module.eks_addons.gitops_metadata.external_dns_iam_role_arn,
          values       = try(yamldecode(join("\n", var.external_dns_helm_config.values)), {}),
          chartVersion = try(var.external_dns_helm_config.chart_version, [])
        }
        karpenter = {
          enabled                   = local.eks_addons.enable_karpenter
          iamRoleArn                = module.eks_addons.gitops_metadata.karpenter_iam_role_arn
          values                    = try(yamldecode(join("\n", var.karpenter_helm_config.values)), {})
          chartVersion              = try(var.karpenter_helm_config.chart_version, [])
          enableCrdWebhookConfig    = try(var.karpenter_helm_config.enable_karpenter_crd_webhook, false)
          truemarkNodeClassDefaults = try(var.karpenter_helm_config.truemark_nodeclass_default, {})
          truemarkNodePoolDefaults  = try(var.karpenter_helm_config.truemark_node_pool_default, {})
          clusterName               = module.eks.cluster_name
          clusterEndpoint           = module.eks.cluster_endpoint
          interruptionQueue         = module.eks_addons.gitops_metadata.karpenter_interruption_queue
          nodeIamRoleName           = module.eks_addons.gitops_metadata.karpenter_node_iam_role_arn
        }
        externalSecrets = {
          enabled      = local.eks_addons.enable_external_secrets,
          iamRoleArn   = module.eks_addons.gitops_metadata.external_secrets_iam_role_arn,
          values       = try(yamldecode(join("\n", var.external_secrets_helm_config.values)), {}),
          chartVersion = try(var.external_secrets_helm_config.chart_version, [])
        }
        metricsServer = {
          enabled      = local.eks_addons.enable_metrics_server,
          values       = try(yamldecode(join("\n", var.metrics_server_helm_config.values)), {}),
          chartVersion = try(var.metrics_server_helm_config.chart_version, [])
        }
        keda = {
          enabled      = local.eks_addons.enable_keda,
          iamRoleArn   = module.eks_addons.gitops_metadata.keda_iam_role_arn,
          values       = try(yamldecode(join("\n", var.keda_helm_config.values)), {}),
          chartVersion = try(var.keda_helm_config.chart_version, [])
        }
        loadBalancerController = {
          enabled      = local.eks_addons.enable_aws_load_balancer_controller,
          iamRoleArn   = module.eks_addons.gitops_metadata.aws_load_balancer_controller_iam_role_arn,
          values       = try(yamldecode(join("\n", var.aws_load_balancer_controller_helm_config.values)), {}),
          clusterName  = module.eks.cluster_name
          chartVersion = try(var.aws_load_balancer_controller_helm_config.chart_version, [])
          vpcId        = var.vpc_id
          serviceAccount = {
            name = module.eks_addons.gitops_metadata.aws_load_balancer_controller_service_account_name
          }
          chartVersion = try(var.aws_load_balancer_controller_helm_config.chart_version, [])
        }
        awsCsiEbsResources = {
          enabled = local.eks_addons.enable_aws_ebs_csi_resources
        }
        istio = {
          chartVersion = try(var.istio_helm_config.chart_version, "1.23.3")
          values       = try(yamldecode(join("\n", var.istio_helm_config.values)), {}),
          base = {
            enabled = local.eks_addons.enable_istio
          }
          ingress_enabled = true
          ingress = {
            external = {
              enabled         = true
              serviceType     = "LoadBalancer"
              certificateArns = try(join(",", var.istio_helm_config.ingress_certificate_arns), "")
            }
            internal = {
              enabled         = false
              serviceType     = "LoadBalancer"
              certificateArns = try(join(",", var.istio_helm_config.ingress_certificate_arns), "")
            }
          }
        }
      }
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
    EOT
    ]
  }
  apps = local.argocd_apps
}

################################################################################
# EKS Blueprints Addons
################################################################################
module "eks_addons" {
  source = "./modules/eks-addons"

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
  enable_cert_manager = local.eks_addons.enable_cert_manager
  cert_manager        = var.cert_manager_helm_config

  # External DNS
  enable_external_dns            = local.eks_addons.enable_external_dns
  external_dns                   = var.external_dns_helm_config
  external_dns_route53_zone_arns = try(var.external_dns_helm_config.route53_zone_arns, [])

  # Karpenter
  enable_karpenter = local.eks_addons.enable_karpenter
  karpenter        = var.karpenter_helm_config

  # External Secrets
  enable_external_secrets = local.eks_addons.enable_external_secrets
  external_secrets        = var.external_secrets_helm_config

  # Metrics Server
  enable_metrics_server = local.eks_addons.enable_metrics_server
  metrics_server        = var.metrics_server_helm_config

  # Keda
  enable_keda = local.eks_addons.enable_keda
  keda        = var.keda_helm_config

  # Load Balancer Controller
  enable_aws_load_balancer_controller = local.eks_addons.enable_aws_load_balancer_controller
  aws_load_balancer_controller        = var.aws_load_balancer_controller_helm_config

  # AWS EBS CSI Resources
  enable_aws_ebs_csi_resources = local.eks_addons.enable_aws_ebs_csi_resources
  #   tags = local.tags
}

