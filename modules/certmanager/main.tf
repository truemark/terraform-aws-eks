locals {
  cert_manager_v15_or_greater = {
    crds = {
      enabled = true
      keep    = true
    }
  }
  cert_manager_v14_or_lower = {
    installCRDS = true
  }
}

resource "helm_release" "cert_manager" {
  name             = "cert-manager"
  repository       = "https://charts.jetstack.io"
  chart            = "cert-manager"
  namespace        = "cert-manager"
  create_namespace = var.create_namespace
  version          = var.cert_manager_chart_version
  values = [
    <<-EOT
    ${tonumber(split(".", var.cert_manager_chart_version)[1]) >= 15 ? yamlencode(local.cert_manager_v15_or_greater) : yamlencode(local.cert_manager_v14_or_lower)}
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
      name  = "dns01RecursiveNameserversOnly"
      value = var.enable_recursive_nameservers
    }
  }

  dynamic "set" {
    for_each = var.enable_recursive_nameservers == true ? [1] : []
    content {
      name  = "dns01RecursiveNameservers"
      value = var.recursive_nameservers
    }
  }

  timeout = 600
}
