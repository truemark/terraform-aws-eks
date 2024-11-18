################################################################################
# Metrics Server
################################################################################
variable "enable_metrics_server" {
  description = "Enable External Secrets operator add-on"
  type        = bool
  default     = false
}

variable "metrics_server" {
  description = "Metrics SErver add-on configuration values"
  type        = any
  default     = {}
}

locals {
  metrics_server_namespace = try(var.metrics_server.namespace, "kube-system")
}

module "metrics_server" {
  source  = "aws-ia/eks-blueprints-addon/aws"
  version = "1.1.1"

  create = var.enable_metrics_server

  # Disable helm release
  create_release = var.create_kubernetes_resources

  # https://github.com/kubernetes-sigs/metrics-server/blob/master/charts/metrics-server/Chart.yaml
  name             = try(var.metrics_server.name, "metrics-server")
  description      = try(var.metrics_server.description, "A Helm chart to install the Metrics Server")
  namespace        = try(var.metrics_server.namespace, "kube-system")
  create_namespace = try(var.metrics_server.create_namespace, false)
  chart            = try(var.metrics_server.chart, "metrics-server")
  chart_version    = try(var.metrics_server.chart_version, "3.12.0")
  repository       = try(var.metrics_server.repository, "https://kubernetes-sigs.github.io/metrics-server/")
  tags             = var.tags
}
