
# # # Install Snapscheduler via Helm
resource "helm_release" "snapscheduler" {
  name             = "snapscheduler"
  chart            = "snapscheduler"
  repository       = "https://backube.github.io/helm-charts/"
  version          = var.chart_version
  namespace        = var.namespace
  create_namespace = true
  values = [
    <<-EOT
    manageCRDs: true
    tolerations: ${jsonencode(var.node_tolerations)}
    EOT
  ]
}
