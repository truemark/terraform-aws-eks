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
  version = "~> 20.14"

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

module "karpenter" {
  count   = var.enable_karpenter ? 1 : 0
  source  = "terraform-aws-modules/eks/aws//modules/karpenter"
  version = "~> 20.14"

  cluster_name = module.eks.cluster_name
  node_iam_role_additional_policies = {
    AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  }
  enable_irsa                     = true
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
  count            = var.enable_karpenter ? 1 : 0
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
    nodeSelector:
      ${jsonencode(var.critical_addons_node_selector)}
    tolerations:
      ${jsonencode(var.critical_addons_node_tolerations)}
    serviceAccount:
      annotations:
        eks.amazonaws.com/role-arn: ${module.karpenter[0].iam_role_arn}
    EOT
  ]
}

resource "kubectl_manifest" "karpenter_node_class" {
  count     = var.enable_karpenter ? 1 : 0
  yaml_body = <<-YAML
    apiVersion: karpenter.k8s.aws/v1beta1
    kind: EC2NodeClass
    metadata:
      name: truemark
    spec:
      amiFamily: ${var.truemark_nodeclass_default_ami_family}
      blockDeviceMappings: ${jsonencode(var.truemark_nodeclass_default_block_device_mappings.specs)}
      role: ${module.karpenter[0].node_iam_role_name}
      subnetSelectorTerms:
        - tags:
            ${jsonencode(var.karpenter_node_template_default.subnetSelector)}
      securityGroupSelectorTerms:
        - tags:
            karpenter.sh/discovery: ${module.eks.cluster_name}
      tags:
        Name: "${module.eks.cluster_name}-truemark-default"
        karpenter.sh/discovery: ${module.eks.cluster_name}
  YAML

  depends_on = [
    helm_release.karpenter
  ]
}

resource "kubectl_manifest" "karpenter_node_pool_arm" {
  count     = var.enable_karpenter ? 1 : 0
  yaml_body = <<-YAML
    apiVersion: karpenter.sh/v1beta1
    kind: NodePool
    metadata:
      name: truemark-arm64
    spec:
      disruption:
        budgets:
          - nodes: 10%
        consolidationPolicy: WhenUnderutilized
        expireAfter: 720h
      template:
        spec:
          nodeClassRef:
            name: truemark
          taints:
          - key: karpenter.sh/nodepool
            value: "truemark-arm64"
            effect: NoSchedule
          requirements: ${jsonencode(var.karpenter_node_pool_default_arm_requirements.requirements)}
      disruption:
        expireAfter: ${var.karpenter_nodepool_default_expireAfter}
        consolidationPolicy: WhenEmpty
        consolidateAfter: 30s
      weight: ${var.karpenter_arm_node_pool_weight}
  YAML

  depends_on = [
    kubectl_manifest.karpenter_node_class
  ]
}

resource "kubectl_manifest" "karpenter_node_pool_amd" {
  count     = var.enable_karpenter ? 1 : 0
  yaml_body = <<-YAML
    apiVersion: karpenter.sh/v1beta1
    kind: NodePool
    metadata:
      name: truemark-amd64
    spec:
      disruption:
        budgets:
          - nodes: 10%
        consolidationPolicy: WhenUnderutilized
        expireAfter: 720h
      template:
        spec:
          nodeClassRef:
            name: truemark
          taints:
          - key: karpenter.sh/nodepool
            value: "truemark-amd64"
            effect: NoSchedule
          requirements: ${jsonencode(var.karpenter_node_pool_default_amd_requirements.requirements)}
      disruption:
        expireAfter: ${var.karpenter_nodepool_default_expireAfter}
        consolidationPolicy: WhenEmpty
        consolidateAfter: 30s
      weight: ${var.karpenter_amd_node_pool_weight}
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
  version    = var.lbc_chart_version

  values = [
    <<-EOT
    clusterName: ${module.eks.cluster_name}
    serviceAccount:
      name: aws-load-balancer-controller
      create: true
      annotations:
        eks.amazonaws.com/role-arn: ${aws_iam_role.aws_load_balancer_controller.arn}
    nodeSelector: ${jsonencode(var.critical_addons_node_selector)}
    tolerations: ${jsonencode(var.critical_addons_node_tolerations)}
    %{if var.lbc_image_tag != null}
    image:
      tag: ${var.lbc_image_tag}
    %{endif}
    EOT
  ]
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

  values = [
    <<-EOT
  nodeSelector:
    ${jsonencode(var.critical_addons_node_selector)}
  tolerations:
    ${jsonencode(var.critical_addons_node_tolerations)}
  webhook:
    nodeSelector:
      ${jsonencode(var.critical_addons_node_selector)}
    tolerations:
      ${jsonencode(var.critical_addons_node_tolerations)}
  certController:
    nodeSelector:
      ${jsonencode(var.critical_addons_node_selector)}
    tolerations:
      ${jsonencode(var.critical_addons_node_tolerations)}
  EOT
  ]

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
  values = [
    <<-EOT
  nodeSelector:
    ${jsonencode(var.critical_addons_node_selector)}
  tolerations:
    ${jsonencode(var.critical_addons_node_tolerations)}
  EOT
  ]
}

module "monitoring" {
  count = var.enable_monitoring ? 1 : 0

  source = "./modules/monitoring"

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
  prometheus_server_request_memory     = var.prometheus_server_request_memory
  prometheus_node_selector             = var.prometheus_node_selector
  prometheus_node_tolerations          = var.prometheus_node_tolerations
  tags                                 = var.tags
}

module "ingress_traefik" {
  count  = var.enable_traefik ? 1 : 0
  source = "./modules/traefik"
}

module "ingress_istio" {
  count  = var.enable_istio ? 1 : 0
  source = "./modules/istio"

  vpc_id                   = var.vpc_id
  istio_release_version    = var.istio_release_version
  istio_nlb_tls_policy     = var.istio_nlb_tls_policy
  aws_managed_prefix_lists = var.aws_managed_prefix_lists
  istio_mesh_id            = var.istio_mesh_id
  istio_network            = var.istio_network
  istio_multi_cluster      = var.istio_multi_cluster
  istio_cluster_name       = var.istio_cluster_name

  istio_enable_external_gateway                         = var.istio_enable_external_gateway
  istio_external_gateway_service_kind                   = var.istio_external_gateway_service_kind
  istio_external_gateway_lb_certs                       = var.istio_external_gateway_lb_certs
  istio_external_gateway_use_prefix_list                = var.istio_external_gateway_use_prefix_list
  istio_external_gateway_enable_http_port               = var.istio_external_gateway_enable_http_port
  istio_external_gateway_lb_source_ranges               = var.istio_external_gateway_lb_source_ranges
  istio_external_gateway_scaling_max_replicas           = var.istio_external_gateway_scaling_max_replicas
  istio_external_gateway_scaling_target_cpu_utilization = var.istio_external_gateway_scaling_target_cpu_utilization
  istio_external_gateway_lb_proxy_protocol              = var.istio_external_gateway_lb_proxy_protocol

  istio_enable_internal_gateway                         = var.istio_enable_internal_gateway
  istio_internal_gateway_enable_http_port               = var.istio_internal_gateway_enable_http_port
  istio_internal_gateway_service_kind                   = var.istio_internal_gateway_service_kind
  istio_internal_gateway_lb_certs                       = var.istio_internal_gateway_lb_certs
  istio_internal_gateway_use_prefix_list                = var.istio_internal_gateway_use_prefix_list
  istio_internal_gateway_lb_source_ranges               = var.istio_internal_gateway_lb_source_ranges
  istio_internal_gateway_scaling_max_replicas           = var.istio_internal_gateway_scaling_max_replicas
  istio_internal_gateway_scaling_target_cpu_utilization = var.istio_internal_gateway_scaling_target_cpu_utilization
  istio_internal_gateway_lb_proxy_protocol              = var.istio_internal_gateway_lb_proxy_protocol
}


module "cert_manager" {
  count = var.enable_cert_manager ? 1 : 0

  source = "./modules/certmanager"

  cert_manager_chart_version   = var.cert_manager_chart_version
  enable_recursive_nameservers = true
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

#### GitOPS Bridge
locals {
  gitops_addons_url      = "${var.gitops_addons_org}/${var.gitops_addons_repo}"
  gitops_addons_basepath = var.gitops_addons_basepath
  gitops_addons_path     = var.gitops_addons_path
  gitops_addons_revision = var.gitops_addons_revision

  addons_metadata = merge(
    #     module.eks_blueprints_addons.gitops_metadata, #TODO: Add again once starting to add blueprints pattern
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
    }
  )

  aws_addons = {
    enable_cert_manager                          = try(var.addons.enable_cert_manager, false)
    enable_aws_efs_csi_driver                    = try(var.addons.enable_aws_efs_csi_driver, false)
    enable_aws_fsx_csi_driver                    = try(var.addons.enable_aws_fsx_csi_driver, false)
    enable_aws_cloudwatch_metrics                = try(var.addons.enable_aws_cloudwatch_metrics, false)
    enable_aws_privateca_issuer                  = try(var.addons.enable_aws_privateca_issuer, false)
    enable_cluster_autoscaler                    = try(var.addons.enable_cluster_autoscaler, false)
    enable_external_dns                          = try(var.addons.enable_external_dns, false)
    enable_external_secrets                      = try(var.addons.enable_external_secrets, false)
    enable_aws_load_balancer_controller          = try(var.addons.enable_aws_load_balancer_controller, false)
    enable_fargate_fluentbit                     = try(var.addons.enable_fargate_fluentbit, false)
    enable_aws_for_fluentbit                     = try(var.addons.enable_aws_for_fluentbit, false)
    enable_aws_node_termination_handler          = try(var.addons.enable_aws_node_termination_handler, false)
    enable_karpenter                             = try(var.addons.enable_karpenter, false)
    enable_velero                                = try(var.addons.enable_velero, false)
    enable_aws_gateway_api_controller            = try(var.addons.enable_aws_gateway_api_controller, false)
    enable_aws_ebs_csi_resources                 = try(var.addons.enable_aws_ebs_csi_resources, false)
    enable_aws_secrets_store_csi_driver_provider = try(var.addons.enable_aws_secrets_store_csi_driver_provider, false)
    enable_ack_apigatewayv2                      = try(var.addons.enable_ack_apigatewayv2, false)
    enable_ack_dynamodb                          = try(var.addons.enable_ack_dynamodb, false)
    enable_ack_s3                                = try(var.addons.enable_ack_s3, false)
    enable_ack_rds                               = try(var.addons.enable_ack_rds, false)
    enable_ack_prometheusservice                 = try(var.addons.enable_ack_prometheusservice, false)
    enable_ack_emrcontainers                     = try(var.addons.enable_ack_emrcontainers, false)
    enable_ack_sfn                               = try(var.addons.enable_ack_sfn, false)
    enable_ack_eventbridge                       = try(var.addons.enable_ack_eventbridge, false)
    enable_aws_argocd_ingress                    = try(var.addons.enable_aws_argocd_ingress, false)
  }
  oss_addons = {
    enable_argocd                          = try(var.addons.enable_argocd, true)
    enable_argo_rollouts                   = try(var.addons.enable_argo_rollouts, false)
    enable_argo_events                     = try(var.addons.enable_argo_events, false)
    enable_argo_workflows                  = try(var.addons.enable_argo_workflows, false)
    enable_cluster_proportional_autoscaler = try(var.addons.enable_cluster_proportional_autoscaler, false)
    enable_gatekeeper                      = try(var.addons.enable_gatekeeper, false)
    enable_gpu_operator                    = try(var.addons.enable_gpu_operator, false)
    enable_ingress_nginx                   = try(var.addons.enable_ingress_nginx, false)
    enable_keda                            = try(var.addons.enable_keda, false)
    enable_kyverno                         = try(var.addons.enable_kyverno, false)
    enable_kube_prometheus_stack           = try(var.addons.enable_kube_prometheus_stack, false)
    enable_metrics_server                  = try(var.addons.enable_metrics_server, false)
    enable_prometheus_adapter              = try(var.addons.enable_prometheus_adapter, false)
    enable_secrets_store_csi_driver        = try(var.addons.enable_secrets_store_csi_driver, false)
    enable_vpa                             = try(var.addons.enable_vpa, false)
  }
  addons = merge(
    local.aws_addons,
    local.oss_addons,
    { kubernetes_version = var.cluster_version },
    { aws_cluster_name = module.eks.cluster_name }
  )
  argocd_apps = {
    addons = file("${path.module}/bootstrap/addons.yaml")
  }

}
module "gitops_bridge_bootstrap" {
  source  = "gitops-bridge-dev/gitops-bridge/helm"
  version = "0.1.0"

  cluster = {
    cluster_name = module.eks.cluster_name
    environment  = var.environment
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

