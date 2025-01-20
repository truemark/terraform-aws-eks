locals {
  addons_context = {
    cluster_name      = var.cluster_name
    oidc_provider_arn = var.oidc_provider_arn
    aws_account_id    = var.aws_account_id
    aws_region        = var.aws_region
    aws_partition     = var.aws_partition
  }
}

module "cert_manager" {
  count          = var.enable_cert_manager ? 1 : 0
  source         = "./cert-manager"
  addons_context = local.addons_context
}

module "external_dns" {
  count          = var.enable_external_dns ? 1 : 0
  source         = "./external-dns"
  addons_context = local.addons_context
}

module "external_secrets" {
  count          = var.enable_external_secrets ? 1 : 0
  source         = "./external-secrets"
  addons_context = local.addons_context
}

module "aws_load_balancer_controller" {
  count          = var.enable_aws_load_balancer_controller ? 1 : 0
  source         = "./aws-load-balancer-controller"
  addons_context = local.addons_context
}

module "karpenter" {
  count          = var.enable_karpenter ? 1 : 0
  source         = "./karpenter"
  addons_context = local.addons_context
}

module "keda" {
  count          = var.enable_keda ? 1 : 0
  source         = "./keda"
  addons_context = local.addons_context
}

module "velero" {
  count          = var.enable_velero ? 1 : 0
  source         = "./velero"
  addons_context = local.addons_context
}

module "observability" {
  count          = var.enable_observability ? 1 : 0
  source         = "./observability"
  addons_context = merge(local.addons_context)
  observability_helm_config = var.observability_helm_config
}
