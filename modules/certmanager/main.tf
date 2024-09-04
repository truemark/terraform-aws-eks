resource "helm_release" "cert_manager" {
  name             = "cert-manager"
  repository       = "https://charts.jetstack.io"
  chart            = "cert-manager"
  namespace        = "cert-manager"
  version          = var.chart_version
  create_namespace = var.create_namespace
  values = [
    <<-EOT
    installCRDs: true
    nodeSelector:
      ${jsonencode(var.certmanager_node_selector)}
    tolerations:
      ${jsonencode(var.certmanager_node_tolerations)}
    cainjector:
      nodeSelector:
        ${jsonencode(var.certmanager_node_selector)}
      tolerations:
        ${jsonencode(var.certmanager_node_tolerations)}
    webhook:
      nodeSelector:
        ${jsonencode(var.certmanager_node_selector)}
      tolerations:
        ${jsonencode(var.certmanager_node_tolerations)}
    startupapicheck:
      nodeSelector:
        ${jsonencode(var.certmanager_node_selector)}
      tolerations:
        ${jsonencode(var.certmanager_node_tolerations)}
    EOT
  ]

  dynamic "set" {
    for_each = var.enable_recursive_nameservers == true ? [1] : []
    content {
      name  = "dns01-recursive-nameservers-only"
      value = var.enable_recursive_nameservers
    }
  }

  dynamic "set" {
    for_each = var.enable_recursive_nameservers == true ? [1] : []
    content {
      name  = "dns01-recursive-nameservers"
      value = var.recursive_nameservers
    }
  }

  timeout = 600
}
