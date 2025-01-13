locals {
  addons_context = {
    cluster_name                     = var.cluster_name
    cluster_security_group_id        = var.cluster_security_group_id
    node_security_group_id           = var.node_security_group_id
    vpc_id                           = var.vpc_id
    oidc_provider_arn                = var.oidc_provider_arn
    aws_account_id                   = var.aws_account_id
    aws_region                       = var.aws_region
    aws_partition                    = var.aws_partition
    auto_mode_system_nodes_config    = var.auto_mode_system_nodes_config
    critical_addons_node_selector    = var.critical_addons_node_selector
    critical_addons_node_tolerations = var.critical_addons_node_tolerations
  }
}

module "cert_manager" {
  count          = var.enable_cert_manager && var.deploy_addons ? 1 : 0
  source         = "./cert-manager"
  addons_context = local.addons_context
}

module "external_dns" {
  count          = var.enable_external_dns && var.deploy_addons ? 1 : 0
  source         = "./external-dns"
  addons_context = local.addons_context
}

module "external_secrets" {
  count          = var.enable_external_secrets && var.deploy_addons ? 1 : 0
  source         = "./external-secrets"
  addons_context = local.addons_context
}

module "aws_load_balancer_controller" {
  count          = var.enable_aws_load_balancer_controller && var.deploy_addons ? 1 : 0
  source         = "./aws-load-balancer-controller"
  addons_context = local.addons_context
}

module "karpenter" {
  count          = var.enable_karpenter && var.deploy_addons ? 1 : 0
  source         = "./karpenter"
  addons_context = local.addons_context
}

module "auto_mode" {
  count          = var.enable_auto_mode && var.deploy_addons ? 1 : 0
  source         = "./eks_auto_mode"
  addons_context = local.addons_context
}

module "keda" {
  count          = var.enable_keda && var.deploy_addons ? 1 : 0
  source         = "./keda"
  addons_context = local.addons_context
}

module "velero" {
  count          = var.enable_velero && var.deploy_addons ? 1 : 0
  source         = "./velero"
  addons_context = local.addons_context
}

module "observability" {
  count          = var.enable_observability && var.deploy_addons ? 1 : 0
  source         = "./observability"
  addons_context = local.addons_context
}
