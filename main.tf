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
  aws_auth_roles = concat(
    [
      for v in var.sso_roles : {
        rolearn  = replace(tolist(data.aws_iam_roles.support_role[v.role_name].arns.*)[0], "aws-reserved/sso.amazonaws.com/${data.aws_region.current.name}/", "")
        username = "${v.role_name}:{{SessionName}}"
        groups   = v.groups
      }
    ],
    [
      for v in var.iam_roles : {
        rolearn  = try(format("arn:aws:iam::%s:role/%s", v.account, v.role_name), (tolist(data.aws_iam_roles.iam_role[v.role_name].arns.*)[0]))
        username = "${v.role_name}:{{SessionName}}"
        groups   = v.groups
      }
    ],
    [
      {
        rolearn  = module.karpenter[0].role_arn
        username = "system:node:{{EC2PrivateDNSName}}"
        groups = [
          "system:bootstrappers",
          "system:nodes",
        ]
      }
    ]
  )
  karpenter_crds = ["karpenter.sh_nodepools.yaml", "karpenter.sh_nodeclaims.yaml", "karpenter.k8s.aws_ec2nodeclasses.yaml"]
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

data "aws_iam_roles" "support_role" {
  for_each    = toset(var.sso_roles.*.role_name)
  name_regex  = "${each.key}_*"
  path_prefix = "/aws-reserved/sso.amazonaws.com/"
}

data "aws_iam_roles" "iam_role" {
  for_each   = toset(var.iam_roles.*.role_name)
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
  version = "~> 19.0"

  cluster_name                            = var.cluster_name
  cluster_version                         = var.cluster_version
  cluster_endpoint_private_access         = var.cluster_endpoint_private_access
  cluster_endpoint_public_access          = var.cluster_endpoint_public_access
  cluster_enabled_log_types               = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
  cluster_security_group_additional_rules = var.cluster_security_group_additional_rules
  node_security_group_additional_rules    = var.node_security_group_additional_rules
  cluster_additional_security_group_ids   = var.cluster_additional_security_group_ids

  #AUTH
  manage_aws_auth_configmap = true
  aws_auth_roles            = local.aws_auth_roles

  #KMS
  kms_key_users  = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
  kms_key_owners = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]

  # OIDC Identity provider
  cluster_identity_providers = {
    sts = {
      client_id = "sts.amazonaws.com"
    }
  }

  cluster_addons = {
    aws-ebs-csi-driver = {
      service_account_role_arn = module.ebs_csi_irsa_role.iam_role_arn
    }
    vpc-cni = {
      resolve_conflicts        = "OVERWRITE"
      service_account_role_arn = module.vpc_cni_irsa.iam_role_arn
    }
  }

  vpc_id     = var.vpc_id
  subnet_ids = var.subnets_ids
  tags       = var.tags

  eks_managed_node_groups = { for k, v in var.eks_managed_node_groups : "${var.cluster_name}-${k}" => v }

  eks_managed_node_group_defaults = {
    iam_role_attach_cni_policy = true
  }

  node_security_group_tags = var.enable_karpenter ? { "karpenter.sh/discovery" = var.cluster_name } : {}
}

module "karpenter" {
  count   = var.enable_karpenter ? 1 : 0
  source  = "terraform-aws-modules/eks/aws//modules/karpenter"
  version = "~> 19.0"

  cluster_name                               = module.eks.cluster_name
  enable_karpenter_instance_profile_creation = true
  iam_role_additional_policies = {
    AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  }
  irsa_oidc_provider_arn          = module.eks.oidc_provider_arn
  irsa_namespace_service_accounts = ["karpenter:karpenter"]

  tags = var.tags
}

data "http" "karpenter_crds" {
  for_each = toset(local.karpenter_crds)
  url      = "https://raw.githubusercontent.com/aws/karpenter/v${var.karpenter_version}/pkg/apis/crds/${each.key}"
}

resource "kubectl_manifest" "karpenter_crds" {
  for_each  = data.http.karpenter_crds
  yaml_body = each.value.body
}

resource "helm_release" "karpenter" {
  namespace        = "karpenter"
  create_namespace = true

  name                = "karpenter"
  repository          = "oci://public.ecr.aws/karpenter"
  repository_username = data.aws_ecrpublic_authorization_token.token[0].user_name
  repository_password = data.aws_ecrpublic_authorization_token.token[0].password
  chart               = "karpenter"
  version             = var.karpenter_version

  values = [
    <<-EOT
    settings:
      clusterName: ${module.eks.cluster_name}
      clusterEndpoint: ${module.eks.cluster_endpoint}
      interruptionQueueName: ${module.karpenter[0].queue_name}
      featureGates:
        drift: ${var.karpenter_settings_featureGates_drift}
    podAnnotations:
      prometheus.io/path: /metrics
      prometheus.io/port: '8000'
      prometheus.io/scrape: 'true'
    serviceAccount:
      annotations:
        eks.amazonaws.com/role-arn: ${module.karpenter[0].irsa_arn}
    EOT
  ]
}

resource "kubectl_manifest" "karpenter_node_class" {
  yaml_body = <<-YAML
    apiVersion: karpenter.k8s.aws/v1beta1
    kind: EC2NodeClass
    metadata:
      name: default
    spec:
      amiFamily: ${var.karpenter_provisioner_default_ami_family}
      blockDeviceMappings: ${jsonencode(var.karpenter_provisioner_default_block_device_mappings.specs)}
      role: ${module.karpenter[0].role_name}
      subnetSelectorTerms:
        - tags:
            ${jsonencode(var.karpenter_node_template_default.subnetSelector)}
      securityGroupSelectorTerms:
        - tags:
            karpenter.sh/discovery: ${module.eks.cluster_name}
      tags:
        karpenter.sh/discovery: ${module.eks.cluster_name}
  YAML

  depends_on = [
    helm_release.karpenter
  ]
}

resource "kubectl_manifest" "karpenter_node_pool" {
  yaml_body = <<-YAML
    apiVersion: karpenter.sh/v1beta1
    kind: NodePool
    metadata:
      name: default
    spec:
      template:
        spec:
          nodeClassRef:
            name: default
          requirements: ${jsonencode(var.karpenter_provisioner_default_requirements.requirements)}
      limits:
        cpu: ${var.karpenter_provisioner_default_cpu_limits}
      disruption:
        expireAfter: ${var.karpenter_nodepool_default_expireAfter}
        consolidationPolicy: WhenEmpty
        consolidateAfter: 30s
  YAML

  depends_on = [
    kubectl_manifest.karpenter_node_class
  ]
}

resource "aws_iam_policy" "aws_load_balancer_controller" {
  name   = "${var.cluster_name}-AWSLoadBalancerControllerIAMPolicy"
  policy = data.aws_iam_policy_document.aws_load_balancer_controller_full.json

  tags = var.tags
}

resource "aws_iam_role" "aws_load_balancer_controller" {
  name               = "${var.cluster_name}-AmazonEKSLoadBalancerControllerRole"
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
        "${local.oidc_provider}:aud": "sts.amazonaws.com",
        "${local.oidc_provider}:sub": "system:serviceaccount:kube-system:aws-load-balancer-controller"
       }
     }
    }
  ]
}
EOF

  tags = var.tags
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
  version    = "1.4.5"

  set {
    name  = "clusterName"
    value = module.eks.cluster_name
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

resource "kubernetes_storage_class" "gp3_xfs_encrypted" {
  metadata {
    name = "gp3-xfs-encrypted"
  }
  storage_provisioner = "ebs.csi.aws.com"
  reclaim_policy      = "Delete"
  parameters = {
    fsType    = "xfs"
    type      = "gp3"
    encrypted = "true"
  }
  volume_binding_mode = "WaitForFirstConsumer"
}

resource "kubernetes_storage_class" "gp3" {
  metadata {
    name = "gp3"
    annotations = {
      "storageclass.kubernetes.io/is-default-class" = "true"
    }
  }
  storage_provisioner = "ebs.csi.aws.com"
  reclaim_policy      = "Delete"
  parameters = {
    fsType = "xfs"
    type   = "gp3"
  }
  volume_binding_mode = "WaitForFirstConsumer"
}

resource "kubectl_manifest" "gp2" {
  yaml_body = <<YAML
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  annotations:
    kubectl.kubernetes.io/last-applied-configuration: |
      {"apiVersion":"storage.k8s.io/v1","kind":"StorageClass","metadata":{"annotations":{"storageclass.kubernetes.io/is-default-class":"false"},"name":"gp2"},"parameters":{"fsType":"ext4","type":"gp2"},"provisioner":"kubernetes.io/aws-ebs","volumeBindingMode":"WaitForFirstConsumer"}
  creationTimestamp: "2022-10-11T15:05:47Z"
  name: gp2
parameters:
  fsType: ext4
  type: gp2
provisioner: kubernetes.io/aws-ebs
reclaimPolicy: Delete
volumeBindingMode: WaitForFirstConsumer
YAML
}

module "external_secrets_irsa" {
  source = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"

  role_name                             = "${var.cluster_name}-ExternalSecrets"
  attach_external_secrets_policy        = true
  external_secrets_ssm_parameter_arns   = var.external_secrets_ssm_parameter_arns
  external_secrets_secrets_manager_arns = var.external_secrets_secrets_manager_arns
  external_secrets_kms_key_arns         = var.external_secrets_kms_key_arns

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["external-secrets:external-secrets"]
    }
  }

  tags = var.tags
}

resource "kubernetes_namespace" "external_secrets" {
  metadata {
    name = "external-secrets"
  }
}

resource "helm_release" "external_secrets" {
  name       = "external-secrets"
  chart      = "external-secrets"
  repository = "https://charts.external-secrets.io"
  version    = "0.7.1"
  namespace  = kubernetes_namespace.external_secrets.id

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = module.external_secrets_irsa.iam_role_arn
  }
}

resource "helm_release" "metrics_server" {
  name       = "metrics-server"
  chart      = "metrics-server"
  repository = "https://kubernetes-sigs.github.io/metrics-server/"
  version    = "3.12.0"
  namespace  = "kube-system"
}

module "monitoring" {
  count = var.enable_monitoring ? 1 : 0

  source  = "truemark/eks-monitoring/aws"
  version = "~> 0.0.15"

  cluster_name                         = module.eks.cluster_name
  amp_name                             = var.amp_arn == null ? "${var.cluster_name}-monitoring" : null
  amp_id                               = var.amp_id
  amp_arn                              = var.amp_arn
  amp_alerting_rules_exclude_namespace = var.amp_alerting_rules_exclude_namespace
  prometheus_server_data_volume_size   = var.prometheus_server_data_volume_size
  cluster_oidc_issuer_url              = module.eks.oidc_provider
  oidc_provider_arn                    = module.eks.oidc_provider_arn
  region                               = data.aws_region.current.name
  alerts_sns_topics_arn                = var.alerts_sns_topics_arn
  amp_custom_alerting_rules            = var.amp_custom_alerting_rules
  tags                                 = var.tags
}

module "ingress_traefik" {
  count   = var.enable_traefik ? 1 : 0
  source  = "truemark/traefik/kubernetes"
  version = "~> 0.0.1"
}

module "ingress_istio" {
  count   = var.enable_istio ? 1 : 0
  source  = "truemark/istio/kubernetes"
  version = "0.0.7"

  vpc_id                              = var.vpc_id
  istio_mesh_id                       = var.istio_mesh_id
  istio_network                       = var.istio_network
  istio_multi_cluster                 = var.istio_multi_cluster
  istio_cluster_name                  = var.istio_cluster_name
  istio_enable_external_gateway       = var.istio_enable_external_gateway
  istio_external_gateway_service_kind = var.istio_external_gateway_service_kind
  istio_external_gateway_lb_certs     = var.istio_external_gateway_lb_certs

  istio_enable_internal_gateway       = var.istio_enable_internal_gateway
  istio_internal_gateway_service_kind = var.istio_internal_gateway_service_kind
  istio_internal_gateway_lb_certs     = var.istio_internal_gateway_lb_certs
}


module "cert_manager" {
  count = var.enable_cert_manager ? 1 : 0

  source  = "truemark/eks-certmanager/aws"
  version = "0.0.4"

  chart_version                = "v1.13.3"
  enable_recursive_nameservers = true
}
