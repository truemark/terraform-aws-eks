module "eks" {
  #########
  # In real deployments source should be replaced with
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
  create_default_critical_addon_node_group = false

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
      role_name = "TrueMarkServiceAutomation"
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
    },
    {
      role_name = "AWSReservedSSO_Administrator"
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

  enable_karpenter  = false
  enable_monitoring = false
  enable_traefik    = false
  enable_istio      = false

  # Compute
  eks_managed_node_groups = {
    system = {
      disk_size      = 50
      min_size       = 1
      max_size       = 3
      desired_size   = 3
      ami_type       = "AL2_ARM_64"
      instance_types = ["t4g.small"]
      labels = {
        "managed" : "eks"
        "purpose" : "system"
      }
      subnet_ids    = data.aws_subnets.private.ids
      capacity_type = "ON_DEMAND"
    }
  }
}
