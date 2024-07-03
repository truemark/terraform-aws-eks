resource "helm_release" "cert_manager" {
  name             = "cert-manager"
  repository       = "https://charts.jetstack.io"
  chart            = "cert-manager"
  namespace        = "cert-manager"
  create_namespace = var.create_namespace

  set {
    name  = "version"
    value = var.chart_version
    type  = "string"
  }

  set {
    name  = "namespace"
    value = "cert-manager"
    type  = "string"
  }

  set {
    name  = "create-namespace"
    value = true
  }

  set {
    name  = "installCRDs"
    value = true
  }

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
