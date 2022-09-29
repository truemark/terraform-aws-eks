data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_id
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}

data "aws_iam_roles" "support_role" {
  for_each    = toset(var.sso_roles.*.role_name)
  name_regex  = "${each.key}_*"
  path_prefix = "/aws-reserved/sso.amazonaws.com/"
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 18.0"

  cluster_name                    = var.cluster_name
  cluster_version                 = "1.23"
  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = true
  cluster_enabled_log_types       = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  aws_auth_roles = [
    for v in var.sso_roles : {
      rolearn  = replace(tolist(data.aws_iam_roles.support_role[v.role_name].arns.*)[0], "aws-reserved/sso.amazonaws.com/${data.aws_region.current.name}/", "")
      username = "${v.role_name}:{{SessionName}}"
      groups   = v.groups
    }
  ]

  # OIDC Identity provider
  cluster_identity_providers = {
    sts = {
      client_id = "sts.amazonaws.com"
    }
  }

  cluster_addons = {
    aws-ebs-csi-driver = {}
  }

  # aws-auth configmap
  manage_aws_auth_configmap = true

  vpc_id     = var.vpc_id
  subnet_ids = var.subnets_ids
  tags       = var.tags

  eks_managed_node_groups         = var.eks_managed_node_groups
  eks_managed_node_group_defaults = var.eks_managed_node_group_defaults

  node_security_group_additional_rules = {
    ingress_allow_access_from_control_plane = {
      type                          = "ingress"
      protocol                      = "tcp"
      from_port                     = 9443
      to_port                       = 9443
      source_cluster_security_group = true
      description                   = "Allow access from control plane to webhook port of AWS load balancer controller"
    }
  }
}

#######################
# Public loadbalancer #
#######################

resource "aws_lb" "public" {
  count              = var.public_alb ? 1 : 0
  name               = "${var.cluster_name}-public"
  load_balancer_type = "application"
  security_groups    = [aws_security_group.public_alb[0].id]
  subnets            = var.public_subnets

  tags = var.tags
}

# Security Group
resource "aws_security_group" "public_alb" {
  count = var.public_alb ? 1 : 0
  name  = "${var.cluster_name}-public-alb"
  # description = var.alb-sg-description
  vpc_id = var.vpc_id

  tags = var.tags
}

# Security Group Rules
resource "aws_security_group_rule" "public_alb_ingress_80" {
  count             = var.public_alb ? 1 : 0
  type              = "ingress"
  security_group_id = aws_security_group.public_alb[0].id
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "public_alb_ingress_443" {
  count             = var.public_alb ? 1 : 0
  type              = "ingress"
  security_group_id = aws_security_group.public_alb[0].id
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "public_alb_egress_allow_all" {
  count             = var.public_alb ? 1 : 0
  type              = "egress"
  security_group_id = aws_security_group.public_alb[0].id
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "public_alb_ingress_80_worker" {
  count                    = var.public_alb ? 1 : 0
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.public_alb[0].id
  security_group_id        = module.eks.node_security_group_id
  description              = "Rule to allow ALB to worker node group"
}

resource "aws_security_group_rule" "public_alb_ingress_443_worker" {
  count                    = var.public_alb ? 1 : 0
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.public_alb[0].id
  security_group_id        = module.eks.node_security_group_id
  description              = "Rule to allow ALB to worker node group"
}

########################
# Private loadbalancer #
########################

# Security Group
resource "aws_security_group" "private_alb" {
  count = var.private_alb ? 1 : 0
  name  = "${var.cluster_name}-private-alb"
  # description = var.alb-sg-description
  vpc_id = var.vpc_id

  tags = var.tags
}

resource "aws_lb" "private" {
  count              = var.private_alb ? 1 : 0
  name               = "${var.cluster_name}-private"
  load_balancer_type = "application"
  security_groups    = [aws_security_group.private_alb[0].id]
  subnets            = var.private_subnets

  tags = var.tags
}

resource "aws_security_group_rule" "private_alb_allow_80_worker" {
  count                    = var.private_alb ? 1 : 0
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.private_alb[0].id
  security_group_id        = module.eks.node_security_group_id
  description              = "Rule to allow ALB to worker node group"
}

resource "aws_security_group_rule" "private_alb_allow_443_worker" {
  count                    = var.private_alb ? 1 : 0
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.private_alb[0].id
  security_group_id        = module.eks.node_security_group_id
  description              = "Rule to allow ALB to worker node group"
}

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.cluster.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
    token                  = data.aws_eks_cluster_auth.cluster.token
  }
}

resource "aws_alb_listener" "public_alb_80" {
  count             = var.public_alb ? 1 : 0
  load_balancer_arn = aws_lb.public[0].arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.public_alb_80[0].arn
  }
}

resource "aws_alb_target_group" "public_alb_80" {
  count       = var.public_alb ? 1 : 0
  name        = "${var.cluster_name}-public-alb-80"
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.vpc_id
}

resource "aws_iam_policy" "aws_load_balancer_controller" {
  name   = "AWSLoadBalancerControllerIAMPolicy1"
  policy = data.aws_iam_policy_document.aws_load_balancer_controller_full.json
}

resource "aws_iam_role" "aws_load_balancer_controller" {
  name               = "AmazonEKSLoadBalancerControllerRole1"
  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Federated": "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${trimprefix(module.eks.cluster_oidc_issuer_url, "https://")}"
            },
            "Action": "sts:AssumeRoleWithWebIdentity",
            "Condition": {
                "StringEquals": {
                    "${trimprefix(module.eks.cluster_oidc_issuer_url, "https://")}:aud": "sts.amazonaws.com",
                    "${trimprefix(module.eks.cluster_oidc_issuer_url, "https://")}:sub": "system:serviceaccount:kube-system:aws-load-balancer-controller"
                }
            }
        }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "aws_load_balancer_controller" {
  role       = aws_iam_role.aws_load_balancer_controller.name
  policy_arn = aws_iam_policy.aws_load_balancer_controller.arn
}

//https://github.com/kubernetes-sigs/aws-load-balancer-controller/releases
resource "helm_release" "aws_load_balancer_controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"

  set {
    name  = "clusterName"
    value = data.aws_eks_cluster.cluster.name
  }

  set {
    name  = "serviceAccount.name"
    value = "aws-load-balancer-controller"
  }

  set {
    name  = "image.repository"
    value = format("602401143452.dkr.ecr.%s.amazonaws.com/amazon/aws-load-balancer-controller", data.aws_region.current.name)
  }

  set {
    name  = "serviceAccount.create"
    value = true
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = aws_iam_role.aws_load_balancer_controller.arn
    type  = "string"
  }

  set {
    name  = "image.tag"
    value = "v2.4.4"
  }
}
