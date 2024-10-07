module "karpenter" {
  source = "./modules/karpenter"

  count = var.enable_karpenter ? 1 : 0

  karpenter_controller_version          = var.karpenter_controller_version
  karpenter_crds_version                = var.karpenter_crds_version
  karpenter_settings_featureGates_drift = var.karpenter_settings_featureGates_drift
  critical_addons_node_selector         = var.critical_addons_node_selector
  critical_addons_node_tolerations      = var.critical_addons_node_tolerations
  tags                                  = var.tags
}

module "castai" {
  source = "./modules/cast-ai"

  enable_cast_ai_agent             = var.enable_cast_ai_agent
  enable_castai_cluster_controller = var.enable_castai_cluster_controller
  enable_castai_spot_handler       = var.enable_castai_spot_handler

  cast_ai_agent_api_key = var.cast_ai_agent_api_key
  cluster_id            = module.eks.cluster_id
}
