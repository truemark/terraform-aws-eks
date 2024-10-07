module "karpenter" {
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

resource "helm_release" "karpenter" {
  namespace        = "karpenter"
  create_namespace = true

  name                = "karpenter"
  repository          = "oci://public.ecr.aws/karpenter"
  repository_username = data.aws_ecrpublic_authorization_token.token[0].user_name
  repository_password = data.aws_ecrpublic_authorization_token.token[0].password
  chart               = "karpenter"
  version             = var.karpenter_controller_version
  skip_crds           = true

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
        eks.amazonaws.com/role-arn: ${module.karpenter.iam_role_arn}
    EOT
  ]
}

resource "helm_release" "karpenter_crds" {
  namespace           = "karpenter"
  name                = "karpenter-crds"
  repository          = "oci://public.ecr.aws/karpenter"
  chart               = "karpenter-crds"
  repository_username = data.aws_ecrpublic_authorization_token.token[0].user_name
  repository_password = data.aws_ecrpublic_authorization_token.token[0].password
  version             = var.karpenter_crds_version

  depends_on = [
    helm_release.karpenter
  ]
}
