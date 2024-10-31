module "karpenter" {
  source  = "terraform-aws-modules/eks/aws//modules/karpenter"
  version = "~> 20.14"

  cluster_name = var.cluster_name
  node_iam_role_additional_policies = {
    AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
    AmazonEFSCSIDriverPolicy     = "arn:aws:iam::aws:policy/service-role/AmazonEFSCSIDriverPolicy"
  }
  enable_irsa                     = true
  irsa_oidc_provider_arn          = var.oidc_provider_arn
  irsa_namespace_service_accounts = ["karpenter:karpenter"]

  tags = var.tags
}

resource "helm_release" "karpenter" {
  namespace        = "karpenter"
  create_namespace = true

  name                = "karpenter"
  repository          = "oci://public.ecr.aws/karpenter"
  repository_username = var.aws_ecrpublic_authorization_token_user_name
  repository_password = var.aws_ecrpublic_authorization_token_user_password
  chart               = "karpenter"
  version             = var.karpenter_controller_version
  skip_crds           = true
  lifecycle {
    ignore_changes = [
      repository_password
    ]
  }
  values = [
    <<-EOT
    settings:
      clusterName: ${var.cluster_name}
      clusterEndpoint: ${var.cluster_endpoint}
      interruptionQueueName: ${module.karpenter.queue_name}
      featureGates:
        drift: ${var.karpenter_settings_featureGates_drift}
    webhook:
      enabled: ${var.enable_karpenter_controller_webhook}
      serviceNamespace: karpenter
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
        eks.amazonaws.com/role-arn: ${module.karpenter.iam_role_arn}
    EOT
  ]
  depends_on = [
    helm_release.karpenter_crd
  ]
}

resource "helm_release" "karpenter_crd" {
  namespace           = "karpenter"
  create_namespace    = true
  name                = "karpenter-crd"
  repository          = "oci://public.ecr.aws/karpenter"
  chart               = "karpenter-crd"
  repository_username = var.aws_ecrpublic_authorization_token_user_name
  repository_password = var.aws_ecrpublic_authorization_token_user_password
  version             = var.karpenter_crds_version
  lifecycle {
    ignore_changes = [
      repository_password
    ]
  }
  dynamic "set" {
    for_each = var.enable_karpenter_crd_webhook ? [1] : []
    content {
      name  = "webhook.enabled"
      value = "true"
    }
  }

  dynamic "set" {
    for_each = var.enable_karpenter_crd_webhook ? [1] : []
    content {
      name  = "webhook.serviceNamespace"
      value = "karpenter"
    }
  }

}
