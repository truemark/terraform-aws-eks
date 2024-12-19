provider "aws" {
  region = "us-east-1"
  alias  = "us-east-1"
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
    ami_type       = "BOTTLEROCKET_ARM_64"
    block_device_mappings = {
      xvda = {
        device_name = "/dev/xvda"
        ebs = {
          volume_size           = 30
          volume_type           = "gp3"
          encrypted             = true
          delete_on_termination = true
          kms_key_id            = var.default_critical_nodegroup_kms_key_id
        }
      }
      xvdb = {
        device_name = "/dev/xvdb"
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
  version = "~> 20"

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
    snapshot-controller = {
      most_recent = true
    }
  }

  vpc_id     = var.vpc_id
  subnet_ids = var.subnets_ids
  tags       = var.tags

  eks_managed_node_groups = local.eks_managed_node_groups

  eks_managed_node_group_defaults = {
    iam_role_attach_cni_policy = true
  }

  node_security_group_tags = var.addons.enable_karpenter ? { "karpenter.sh/discovery" = var.cluster_name } : {}
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
