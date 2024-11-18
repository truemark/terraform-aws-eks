###############################################
# EKS Addons Configuration
###############################################

# Define Kubernetes addons to enable/disable.
variable "addons" {
  description = <<-EOT
    A map to enable or disable various Kubernetes addons.
    Example addons: AWS Load Balancer Controller, Metrics Server.
  EOT
  type = object({
    enable_aws_load_balancer_controller = optional(bool, false)
    enable_metrics_server               = optional(bool, false)
    enable_argocd                       = optional(bool, false)
    enable_cert_manager                 = optional(bool, false)
    enable_external_dns                 = optional(bool, false)
    enable_istio                        = optional(bool, false)
    enable_istio_ingress                = optional(bool, false)
    enable_karpenter                    = optional(bool, false)
    enable_external_secrets             = optional(bool, false)
    enable_keda                         = optional(bool, false)
    enable_aws_ebs_csi_resources        = optional(bool, false)
  })
}

# Define GitOps-related repository configuration.
variable "gitops_addons_org" {
  description = "GitHub organization/user containing addons Git repository."
  type        = string
  default     = "https://github.com/aws-samples"
}

variable "gitops_addons_repo" {
  description = "Git repository containing addons."
  type        = string
  default     = "eks-blueprints-add-ons"
}

variable "gitops_addons_revision" {
  description = "Git repository branch, tag, or revision for addons."
  type        = string
  default     = "main"
}

variable "gitops_addons_basepath" {
  description = "Base path within the Git repository for addons."
  type        = string
  default     = "argocd/"
}

variable "gitops_addons_path" {
  description = "Specific path within the Git repository for addons."
  type        = string
  default     = "bootstrap/control-plane/addons"
}

###############################################
# Local Variables
###############################################

# Dynamically resolve the state of enabled addons based on input.
locals {
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

  # Metadata for addons configuration.
  addons_metadata = merge(
    {
      aws_cluster_name = module.eks.cluster_name
      aws_region       = data.aws_region.current.name
      aws_account_id   = data.aws_caller_identity.current.account_id
      aws_vpc_id       = var.vpc_id
    }
  )

  # Tags for resources.
  tags = {
    Blueprint = var.cluster_name
  }

  # ArgoCD application configurations.
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
        # Additional addon configurations here...
      }
    }
  }
}

###############################################
# Modules and GitOps Bridge
###############################################

# GitOps Bridge Bootstrap Configuration
variable "enable_gitops_bridge_bootstrap" {
  description = "Enable or disable the GitOps bridge bootstrap module."
  type        = bool
  default     = true
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

###############################################
# EKS Addons Module
###############################################

module "eks_addons" {
  source = "./modules/eks-addons"

  # AWS and cluster configurations
  oidc_provider_arn                = module.eks.oidc_provider_arn
  aws_region                       = data.aws_region.current.name
  aws_account_id                   = data.aws_caller_identity.current.account_id
  aws_partition                    = data.aws_partition.current.partition
  cluster_name                     = module.eks.cluster_name
  cluster_endpoint                 = module.eks.cluster_endpoint
  cluster_version                  = var.cluster_version

  # Node selector and tolerations
  critical_addons_node_selector    = var.critical_addons_node_selector
  critical_addons_node_tolerations = var.critical_addons_node_tolerations

  # Addons configurations
  enable_cert_manager              = local.eks_addons.enable_cert_manager
  cert_manager                     = var.cert_manager_helm_config

  enable_external_dns              = local.eks_addons.enable_external_dns
  external_dns                     = var.external_dns_helm_config
  external_dns_route53_zone_arns   = try(var.external_dns_helm_config.route53_zone_arns, [])

  enable_karpenter                 = local.eks_addons.enable_karpenter
  karpenter                        = var.karpenter_helm_config

  enable_external_secrets          = local.eks_addons.enable_external_secrets
  external_secrets                 = var.external_secrets_helm_config

  enable_metrics_server            = local.eks_addons.enable_metrics_server
  metrics_server                   = var.metrics_server_helm_config

  enable_keda                      = local.eks_addons.enable_keda
  keda                             = var.keda_helm_config

  enable_aws_load_balancer_controller = local.eks_addons.enable_aws_load_balancer_controller
  aws_load_balancer_controller        = var.aws_load_balancer_controller_helm_config

  enable_aws_ebs_csi_resources = local.eks_addons.enable_aws_ebs_csi_resources
}
