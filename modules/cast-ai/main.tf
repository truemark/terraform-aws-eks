resource "helm_release" "cast_ai_agent" {
  count = var.enable_cast_ai_agent ? 1 : 0

  name       = "castai-agent"
  chart      = "castai-agent"
  namespace  = "castai-agent"
  repository = "https://castai.github.io/charts"
  set {
    name  = "apiKey"
    value = var.cast_ai_agent_api_key
  }
  set {
    name  = "provider"
    value = "eks"
  }
}

resource "helm_release" "castai_cluster_controller" {
  count = var.enable_castai_cluster_controller ? 1 : 0

  name       = "castai-cluster-controller"
  chart      = "castai-cluster-controller"
  namespace  = "castai-agent"
  repository = "https://castai.github.io/charts"
  set {
    name  = "apiKey"
    value = var.cast_ai_agent_api_key
  }
  set {
    name  = "clusterID"
    value = var.cluster_id
  }
}

resource "helm_release" "castai_spot_handler" {
  count = var.enable_castai_spot_handler ? 1 : 0

  name       = "castai-spot-handler"
  chart      = "castai-spot-handler"
  namespace  = "castai-agent"
  repository = "https://castai.github.io/charts"
  set {
    name  = "provider"
    value = "eks"
  }
  set {
    name  = "clusterID"
    value = var.cluster_id
  }
}
