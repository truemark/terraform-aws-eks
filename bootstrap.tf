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
    enable_argocd       = try(var.addons.enable_argocd, false)
    enable_cert_manager = try(var.addons.enable_cert_manager, false)
    enable_external_dns = try(var.addons.enable_external_dns, false)
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

  oidc_provider_arn = module.eks.oidc_provider_arn
  aws_region        = data.aws_region.current.name
  aws_account_id    = data.aws_caller_identity.current.account_id
  aws_partition     = data.aws_partition.current.partition
  cluster_name      = module.eks.cluster_name
  cluster_endpoint  = module.eks.cluster_endpoint
  cluster_version   = var.cluster_version


  # Using GitOps Bridge
  create_kubernetes_resources = var.enable_gitops_bridge_bootstrap ? false : true

  # Cert Manager
  enable_cert_manager = local.eks_addons.enable_cert_manager
  cert_manager        = var.cert_manager_helm_config

  # External DNS
  enable_external_dns = local.eks_addons.enable_external_dns
  external_dns        = var.external_dns_helm_config
  external_dns_route53_zone_arns = try(var.external_dns_helm_config.route53_zone_arns, [])

  #   tags = local.tags
}
