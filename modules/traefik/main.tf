resource "helm_release" "traefik" {
  name             = var.traefik_release_name
  repository       = "https://traefik.github.io/charts"
  chart            = "traefik"
  version          = var.traefik_release_version
  namespace        = var.traefik_release_namespace
  create_namespace = var.traefik_create_namespace
  values = [
    templatefile("${path.module}/values.yml", {
      is_default_class = var.traefik_ingress_is_default_class
      entrypoints      = var.traefik_enabled_entrypoints
    })
  ]
}
