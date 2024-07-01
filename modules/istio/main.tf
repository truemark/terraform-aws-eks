data "aws_subnets" "istio_private_subnet_ids" {
  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }
  tags = {
    network = "private"
  }
}

data "aws_subnets" "istio_public_subnet_ids" {
  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }
  tags = {
    network = "public"
  }
}

data "aws_ec2_managed_prefix_list" "this" {
  for_each = var.aws_managed_prefix_lists
  name     = each.value
}

resource "helm_release" "istio_base" {
  name             = "istio-base"
  repository       = "https://istio-release.storage.googleapis.com/charts"
  chart            = "base"
  version          = var.istio_release_version
  namespace        = var.istio_release_namespace
  create_namespace = true
  set {
    name  = "defaultRevision"
    value = "default"
  }
}

resource "helm_release" "istio_discovery" {
  name             = "istio-discovery"
  repository       = "https://istio-release.storage.googleapis.com/charts"
  chart            = "istiod"
  version          = var.istio_release_version
  namespace        = var.istio_release_namespace
  create_namespace = true
  values = [
    templatefile("${path.module}/values/istiod.tftpl", {
      istio_mesh_id       = var.istio_mesh_id
      istio_network       = var.istio_network
      istio_multi_cluster = var.istio_multi_cluster
      istio_cluster_name  = var.istio_cluster_name
    })
  ]
  depends_on = [helm_release.istio_base]
}


resource "kubectl_manifest" "envoy_filters" {
  for_each  = { for file in fileset("${path.module}/manifests", "*") : file => "${path.module}/manifests/${file}" }
  yaml_body = file(each.value)
}

resource "helm_release" "istio_gateway_external" {
  count            = var.istio_enable_external_gateway ? 1 : 0
  name             = "istio-gateway-external"
  repository       = "https://istio-release.storage.googleapis.com/charts"
  chart            = "gateway"
  version          = var.istio_release_version
  namespace        = "istio-system"
  create_namespace = true
  values = [
    templatefile("${path.module}/values/external-gateway.tftpl", {
      external_gateway_service_kind                   = var.istio_external_gateway_service_kind
      enable_http_port                                = var.istio_external_gateway_enable_http_port
      external_gateway_lb_subnets                     = join(",", data.aws_subnets.istio_public_subnet_ids.ids)
      external_gateway_lb_certs                       = join(",", var.istio_external_gateway_lb_certs)
      external_gateway_scaling_max_replicas           = var.istio_external_gateway_scaling_max_replicas
      external_gateway_scaling_target_cpu_utilization = var.istio_external_gateway_scaling_target_cpu_utilization
      external_gateway_lb_proxy_protocol              = var.istio_external_gateway_lb_proxy_protocol
      external_gateway_lb_source_ranges               = join(",", var.istio_external_gateway_lb_source_ranges)
      istio_nlb_tls_policy                            = var.istio_nlb_tls_policy
      use_prefix_list                                 = var.istio_external_gateway_use_prefix_list
      lb_security_group_prefix_lists                  = join(",", values(data.aws_ec2_managed_prefix_list.this).*.id)
    })
  ]
  depends_on = [helm_release.istio_base, helm_release.istio_discovery]
}

resource "helm_release" "istio_gateway_internal" {
  count            = var.istio_enable_internal_gateway ? 1 : 0
  name             = "istio-gateway-internal"
  repository       = "https://istio-release.storage.googleapis.com/charts"
  chart            = "gateway"
  version          = var.istio_release_version
  namespace        = "istio-system"
  create_namespace = true
  values = [
    templatefile("${path.module}/values/internal-gateway.tftpl", {
      internal_gateway_service_kind                   = var.istio_internal_gateway_service_kind
      enable_http_port                                = var.istio_internal_gateway_enable_http_port
      internal_gateway_lb_subnets                     = join(",", data.aws_subnets.istio_private_subnet_ids.ids)
      internal_gateway_lb_certs                       = join(",", var.istio_internal_gateway_lb_certs)
      internal_gateway_scaling_max_replicas           = var.istio_internal_gateway_scaling_max_replicas
      internal_gateway_scaling_target_cpu_utilization = var.istio_internal_gateway_scaling_target_cpu_utilization
      internal_gateway_lb_proxy_protocol              = var.istio_internal_gateway_lb_proxy_protocol
      internal_gateway_lb_source_ranges               = join(",", var.istio_internal_gateway_lb_source_ranges)
      istio_nlb_tls_policy                            = var.istio_nlb_tls_policy
      use_prefix_list                                 = var.istio_internal_gateway_use_prefix_list
      lb_security_group_prefix_lists                  = join(",", values(data.aws_ec2_managed_prefix_list.this).*.id)
    })
  ]
  depends_on = [helm_release.istio_base, helm_release.istio_discovery]
}
