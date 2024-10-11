module "karpenter" {
  source = "./modules/karpenter"

  count = var.enable_karpenter ? 1 : 0

  cluster_name                                    = var.cluster_name
  oidc_provider_arn                               = module.eks.oidc_provider_arn
  cluster_endpoint                                = module.eks.cluster_endpoint
  aws_ecrpublic_authorization_token_user_name     = data.aws_ecrpublic_authorization_token.token[0].user_name
  aws_ecrpublic_authorization_token_user_password = data.aws_ecrpublic_authorization_token.token[0].password
  karpenter_controller_version                    = var.karpenter_controller_version
  karpenter_crds_version                          = var.karpenter_crds_version
  enable_karpenter_controller_webhook             = var.enable_karpenter_controller_webhook
  enable_karpenter_crd_webhook                    = var.enable_karpenter_crd_webhook
  karpenter_settings_featureGates_drift           = var.karpenter_settings_featureGates_drift
  critical_addons_node_selector                   = var.critical_addons_node_selector
  critical_addons_node_tolerations                = var.critical_addons_node_tolerations
  tags                                            = var.tags
}

module "castai" {
  source = "./modules/cast-ai"

  enable_cast_ai_agent             = var.enable_cast_ai_agent
  enable_castai_cluster_controller = var.enable_castai_cluster_controller
  enable_castai_spot_handler       = var.enable_castai_spot_handler

  cast_ai_agent_api_key = var.cast_ai_agent_api_key
  cluster_id            = module.eks.cluster_id
}
