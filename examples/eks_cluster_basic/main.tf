module "eks" {
  #########
  # In production deployments source should be replaced with
  # source                          = "truemark/eks/aws"
  # version                         = "1.1.4"
  #########
  source                                   = "../../"
  cluster_name                             = var.cluster_name
  cluster_version                          = var.cluster_version
  cluster_endpoint_private_access          = true
  cluster_endpoint_public_access           = true
  create_cloudwatch_log_group              = true
  vpc_id                                   = data.aws_vpc.services.id
  subnets_ids                              = data.aws_subnets.private.ids
  create_default_critical_addon_node_group = true

  ## RBAC/IAM Roles
  eks_access_account_iam_roles = [
    {
      role_name = "github-devops-provisioner"
      access_scope = {
        type       = "cluster"
        namespaces = null
      }
      policy_name = "AmazonEKSClusterAdminPolicy"
    },
    {
      role_name = "AWSReservedSSO_Developer_"
      access_scope = {
        type       = "cluster"
        namespaces = null
      }
      policy_name = "AmazonEKSClusterAdminPolicy"
    }
  ]

  eks_access_cross_account_iam_roles = [
  ]

  # Security Groups
  node_security_group_additional_rules = {
    ingress_all_from_cluster = {
      description              = "Allow all taffic from cluster sg"
      from_port                = 0
      to_port                  = 0
      protocol                 = "-1"
      type                     = "ingress"
      source_security_group_id = module.eks.cluster_security_group_id
    }
  }

  cluster_security_group_additional_rules = {
    ingress_all_from_nodes = {
      description              = "Allow all taffic from nodes sg"
      from_port                = 0
      to_port                  = 0
      protocol                 = "-1"
      type                     = "ingress"
      source_security_group_id = module.eks.node_security_group_id
    }
  }

  enable_karpenter              = true
  enable_monitoring             = false
  enable_traefik                = false
  enable_istio                  = false
  istio_enable_external_gateway = false

  karpenter_node_pool_default_arm_requirements = {
    requirements = [
      {
        key      = "karpenter.k8s.aws/instance-category"
        operator = "In"
        values   = ["m", "c", "r"]
      },
      {
        key      = "karpenter.k8s.aws/instance-cpu"
        operator = "In"
        values   = ["4", "8", "16"]
      },
      {
        key      = "karpenter.k8s.aws/instance-hypervisor"
        operator = "In"
        values   = ["nitro"]
      },
      {
        key      = "kubernetes.io/arch"
        operator = "In"
        values   = ["arm64"]
      },
      {
        key      = "karpenter.sh/capacity-type"
        operator = "In"
        values   = ["spot"]
      }
    ]
  }

  karpenter_node_pool_default_amd_requirements = {
    requirements = [
      {
        key      = "karpenter.k8s.aws/instance-category"
        operator = "In"
        values   = ["m", "c", "r"]
      },
      {
        key      = "karpenter.k8s.aws/instance-cpu"
        operator = "In"
        values   = ["4", "8", "16"]
      },
      {
        key      = "karpenter.k8s.aws/instance-hypervisor"
        operator = "In"
        values   = ["nitro"]
      },
      {
        key      = "kubernetes.io/arch"
        operator = "In"
        values   = ["amd64"]
      },
      {
        key      = "karpenter.sh/capacity-type"
        operator = "In"
        values   = ["spot"]
      }
    ]
  }
}
