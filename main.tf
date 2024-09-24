data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

provider "aws" {
  region = "us-east-1"
  alias  = "us-east-1"
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_name
}

data "aws_ecrpublic_authorization_token" "token" {
  count    = var.enable_karpenter ? 1 : 0
  provider = aws.us-east-1
}

locals {
  oidc_provider            = replace(module.eks.cluster_oidc_issuer_url, "https://", "")
  iamproxy-service-account = "${var.cluster_name}-iamproxy-service-account"
  eks_access_iam_roles_map = { for role in var.eks_access_account_iam_roles : role.role_name => role }
  eks_access_entries = merge(
    { for role in data.aws_iam_roles.eks_access_iam_roles : role.name_regex => merge(local.eks_access_iam_roles_map[role.name_regex], { "arn" : tolist(role.arns)[0] }) },
    { for role in var.eks_access_cross_account_iam_roles : role.role_name => merge({ "role_name" = role.role_name, "access_scope" = role.access_scope, "policy_name" = role.policy_name, "arn" = role.prefix != null ? format("arn:aws:iam::%s:role/%s/%s", role.account, role.prefix, role.role_name) : format("arn:aws:iam::%s:role/%s", role.account, role.role_name) }) }
  )
  default_critical_addon_nodegroup = {
    instance_types = var.default_critical_addon_node_group_instance_types
    ami_type       = "AL2023_ARM_64_STANDARD"
    block_device_mappings = {
      xvda = {
        device_name = "/dev/xvda"
        ebs = {
          volume_size           = 100
          volume_type           = "gp3"
          encrypted             = true
          delete_on_termination = true
          kms_key_id            = var.default_critical_nodegroup_kms_key_id
        }
      }
    }
    min_size     = 3
    max_size     = 3
    desired_size = 3

    labels = {
      CriticalAddonsOnly = "true"
    }

    taints = {
      addons = {
        key    = "CriticalAddonsOnly"
        value  = "true"
        effect = "NO_SCHEDULE"
      },
    }
  }
  eks_managed_node_groups = merge(
    { for k, v in var.eks_managed_node_groups : "${var.cluster_name}-${k}" => v },
    var.create_default_critical_addon_node_group ? {
      "truemark-system" = local.default_critical_addon_nodegroup
    } : {}
  )
  karpenter_crds = var.enable_karpenter ? ["karpenter.sh_nodepools.yaml", "karpenter.sh_nodeclaims.yaml", "karpenter.k8s.aws_ec2nodeclasses.yaml"] : []
}

provider "kubectl" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.cluster.token
  load_config_file       = false
}

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}

provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
    token                  = data.aws_eks_cluster_auth.cluster.token
  }
}

data "aws_iam_roles" "eks_access_iam_roles" {
  for_each   = toset(var.eks_access_account_iam_roles.*.role_name)
  name_regex = each.key
}

module "ebs_csi_irsa_role" {
  source = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"

  role_name = "${var.cluster_name}-AmazonEKS_EBS_CSI_DriverRole"

  attach_ebs_csi_policy = true
  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:ebs-csi-controller-sa"]
    }
  }

  tags = var.tags
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.24"

  cluster_name                             = var.cluster_name
  cluster_version                          = var.cluster_version
  cluster_endpoint_private_access          = var.cluster_endpoint_private_access
  cluster_endpoint_public_access           = var.cluster_endpoint_public_access
  create_cloudwatch_log_group              = var.create_cloudwatch_log_group
  cluster_enabled_log_types                = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
  cluster_security_group_additional_rules  = var.cluster_security_group_additional_rules
  node_security_group_additional_rules     = var.node_security_group_additional_rules
  cluster_additional_security_group_ids    = var.cluster_additional_security_group_ids
  enable_cluster_creator_admin_permissions = var.enable_cluster_creator_admin_permissions

  #KMS
  kms_key_users  = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
  kms_key_owners = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]

  cluster_addons = {
    vpc-cni = {
      most_recent              = true
      before_compute           = var.vpc_cni_before_compute
      service_account_role_arn = module.vpc_cni_irsa.iam_role_arn
    }
    eks-pod-identity-agent = {
      most_recent = true
    }
    aws-ebs-csi-driver = {
      most_recent              = true
      service_account_role_arn = module.ebs_csi_irsa_role.iam_role_arn
    }
  }

  vpc_id     = var.vpc_id
  subnet_ids = var.subnets_ids
  tags       = var.tags

  eks_managed_node_groups = local.eks_managed_node_groups

  eks_managed_node_group_defaults = {
    iam_role_attach_cni_policy = true
  }

  node_security_group_tags = var.enable_karpenter ? { "karpenter.sh/discovery" = var.cluster_name } : {}
}

resource "aws_eks_access_entry" "access_entries" {
  for_each = local.eks_access_entries

  cluster_name  = module.eks.cluster_name
  principal_arn = each.value.arn
  user_name     = "${each.key}:{{SessionName}}"
}

resource "aws_eks_access_policy_association" "access_policy_associations" {
  for_each = local.eks_access_entries

  cluster_name  = module.eks.cluster_name
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/${each.value.policy_name}"
  principal_arn = each.value.arn
  dynamic "access_scope" {
    for_each = each.value.access_scope != null ? [each.value.access_scope] : []
    content {
      type       = access_scope.value.type
      namespaces = access_scope.value.namespaces != null ? access_scope.value.namespaces : []
    }
  }
}

module "vpc_cni_irsa" {
  source = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"

  role_name             = "${var.cluster_name}-AmazonEKSVPCCNIRole"
  attach_vpc_cni_policy = true
  vpc_cni_enable_ipv4   = true

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:aws-node"]
    }
  }

  tags = var.tags
}

resource "kubernetes_storage_class" "gp3_ext4_encrypted" {
  metadata {
    name = "gp3-ext4-encrypted"
    annotations = {
      "storageclass.kubernetes.io/is-default-class" = "true"
    }
  }
  storage_provisioner = "ebs.csi.aws.com"
  reclaim_policy      = "Delete"
  parameters = {
    fsType    = "ext4"
    type      = "gp3"
    encrypted = "true"
  }
  volume_binding_mode = "WaitForFirstConsumer"
}

resource "kubernetes_annotations" "remove_default_gp2" {
  api_version = "storage.k8s.io/v1"
  kind        = "StorageClass"
  metadata {
    name = "gp2"
  }
  annotations = {
    "storageclass.kubernetes.io/is-default-class" = "false"
  }
}

################################################################################
# GitOps Bridge: Bootstrap
################################################################################
locals {
  environment            = var.environment
  gitops_addons_url      = "${var.gitops_addons_org}/${var.gitops_addons_repo}"
  gitops_addons_basepath = var.gitops_addons_basepath
  gitops_addons_path     = var.gitops_addons_path
  gitops_addons_revision = var.gitops_addons_revision
  aws_addons = {
    enable_cert_manager                 = try(var.addons.enable_cert_manager, false)
    enable_cluster_autoscaler           = try(var.addons.enable_cluster_autoscaler, false)
    enable_external_dns                 = try(var.addons.enable_external_dns, false)
    enable_external_secrets             = try(var.addons.enable_external_secrets, false)
    enable_aws_load_balancer_controller = try(var.addons.enable_aws_load_balancer_controller, false)
    enable_karpenter                    = try(var.addons.enable_karpenter, false)
    enable_velero                       = try(var.addons.enable_velero, false)
  }
  oss_addons = {
    enable_argocd                = try(var.addons.enable_argocd, true)
    enable_argo_rollouts         = try(var.addons.enable_argo_rollouts, false)
    enable_argo_events           = try(var.addons.enable_argo_events, false)
    enable_argo_workflows        = try(var.addons.enable_argo_workflows, false)
    enable_keda                  = try(var.addons.enable_keda, false)
    enable_kyverno               = try(var.addons.enable_kyverno, false)
    enable_kube_prometheus_stack = try(var.addons.enable_kube_prometheus_stack, false)
    enable_metrics_server        = try(var.addons.enable_metrics_server, false)
    enable_prometheus_adapter    = try(var.addons.enable_prometheus_adapter, false)
    enable_vpa                   = try(var.addons.enable_vpa, false)
  }
  addons = merge(
    local.aws_addons,
    local.oss_addons,
    { kubernetes_version = var.cluster_version },
    { aws_cluster_name = module.eks.cluster_name }
  )
  addons_metadata = merge(
    module.eks_blueprints_addons.gitops_metadata,
    {
      aws_cluster_name = module.eks.cluster_name
      aws_region       = data.aws_region.current.name
      aws_account_id   = data.aws_caller_identity.current.account_id
      aws_vpc_id       = var.vpc_id
    },
    {
      # Required for external dns addon
      external_dns_domain_filters = "example.com"
    },
    {
      addons_repo_url      = local.gitops_addons_url
      addons_repo_basepath = local.gitops_addons_basepath
      addons_repo_path     = local.gitops_addons_path
      addons_repo_revision = local.gitops_addons_revision
    },
    {
      critical_addons_node_selector    = jsonencode(var.critical_addons_node_selector)
      critical_addons_node_tolerations = jsonencode(var.critical_addons_node_tolerations)
      arm_64_node_selector             = jsonencode(var.truemark_arm_node_selector)
      arm_64_node_tolerations          = jsonencode(var.truemark_arm_node_tolerations)
    }
  )
  argocd_apps = {
    addons    = file("${path.module}/bootstrap/addons.yaml")
    workloads = file("${path.module}/bootstrap/workloads.yaml")
  }
}

module "gitops_bridge_bootstrap" {
  source = "./modules/terraform-helm-gitops-bridge"

  cluster = {
    cluster_name = module.eks.cluster_name
    environment  = local.environment
    metadata     = local.addons_metadata
    addons       = local.addons
  }
  argocd = {
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

module "eks_blueprints_addons" {
  source = "./modules/kubernetes-addons"
  #   version = "~> 1.0"

  cluster_name      = module.eks.cluster_name
  cluster_endpoint  = module.eks.cluster_endpoint
  cluster_version   = module.eks.cluster_version
  oidc_provider_arn = module.eks.oidc_provider_arn

  # Using GitOps Bridge
  create_kubernetes_resources = false

  # EKS Blueprints Addons
  enable_cert_manager = true
  cert_manager = {
    chart_version = "v1.15.3"
  }
}

output "argocd" {
  value = {
    labels      = module.gitops_bridge_bootstrap.argocd_labels
    annotations = module.gitops_bridge_bootstrap.argocd_annotations
  }
}

resource "aws_ssm_parameter" "cluster_id" {
  name           = "/truemark/eks/${var.cluster_name}/cluster_id"
  description    = "The name/id of the EKS cluster. Will block on cluster creation until the cluster is really ready"
  type           = "String"
  value          = module.eks.cluster_id
  insecure_value = true
  tags           = var.tags
}

resource "aws_ssm_parameter" "cluster_endpoint" {
  name        = "/truemark/eks/${var.cluster_name}/cluster_endpoint"
  description = "Endpoint of the Kubernetes API server"
  type        = "String"
  value       = module.eks.cluster_endpoint
  tags        = var.tags
}

resource "aws_ssm_parameter" "cluster_arn" {
  name        = "/truemark/eks/${var.cluster_name}/arn"
  description = "The Amazon Resource Name (ARN) of the cluster"
  type        = "String"
  value       = module.eks.cluster_arn
  tags        = var.tags
}

resource "aws_ssm_parameter" "oidc_provider" {
  name        = "/truemark/eks/${var.cluster_name}/oidc_provider"
  description = "The OpenID Connect identity provider (issuer URL without leading `https://`)"
  type        = "String"
  value       = module.eks.oidc_provider
  tags        = var.tags
}

resource "aws_ssm_parameter" "oidc_provider_arn" {
  name        = "/truemark/eks/${var.cluster_name}/oidc_provider_arn"
  description = "The ARN of the OIDC Provider"
  type        = "String"
  value       = module.eks.oidc_provider_arn
  tags        = var.tags
}

resource "aws_ssm_parameter" "cluster_certificate_authority_data" {
  name        = "/truemark/eks/${var.cluster_name}/cluster_certificate_authority_data"
  description = "Base64 encoded certificate data required to communicate with the cluster"
  type        = "String"
  value       = module.eks.cluster_certificate_authority_data
  tags        = var.tags
}
