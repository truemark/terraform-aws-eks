resource "helm_release" "vpa" {
  count            = var.vpa_enabled ? 1 : 0
  chart            = "vpa"
  name             = "vpa"
  namespace        = "vpa"
  create_namespace = true
  repository       = "https://charts.fairwinds.com/stable"
  values = [
  <<-EOT
  recommender:
    nodeSelector:
      ${jsonencode(var.critical_addons_node_selector)}
    tolerations:
      ${jsonencode(var.critical_addons_node_tolerations)}
  updater:
    enabled: false
    nodeSelector:
      ${jsonencode(var.critical_addons_node_selector)}
    tolerations:
      ${jsonencode(var.critical_addons_node_tolerations)}
  admissionController:
    nodeSelector:
      ${jsonencode(var.critical_addons_node_selector)}
    tolerations:
      ${jsonencode(var.critical_addons_node_tolerations)}
    certGen:
      nodeSelector: {
        "karpenter.sh/nodepool": "truemark-amd64"
      }
      tolerations: [
        {
          "key": "karpenter.sh/nodepool",
          "operator": "Equal",
          "effect": "NoSchedule",
          "value": "truemark-amd64"
        }
      ]
  EOT
  ]
}

## https://goldilocks.docs.fairwinds.com/
resource "helm_release" "fairwinds_goldirocks" {
  count            = (var.vpa_enabled && var.goldilocks_enabled) ? 1 : 0
  chart            = "goldilocks"
  name             = "goldilocks"
  namespace        = "vpa"
  create_namespace = true
  repository       = "https://charts.fairwinds.com/stable"
  values = [
    <<-EOT
    vpa:
      enabled: false
      updater:
        enabled: false
    nodeSelector:
      ${jsonencode(var.critical_addons_node_selector)}
    tolerations:
      ${jsonencode(var.critical_addons_node_tolerations)}
    controller:
      nodeSelector:
        ${jsonencode(var.critical_addons_node_selector)}
      tolerations:
        ${jsonencode(var.critical_addons_node_tolerations)}
    dashboard:
      nodeSelector:
        ${jsonencode(var.critical_addons_node_selector)}
      tolerations:
        ${jsonencode(var.critical_addons_node_tolerations)}
  EOT
  ]
  depends_on = [helm_release.vpa]
}
