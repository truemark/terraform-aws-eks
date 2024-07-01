moved {
  from = helm_release.istio-base
  to   = helm_release.istio_base
}

moved {
  from = helm_release.istio-discovery
  to   = helm_release.istio_discovery
}

moved {
  from = helm_release.istio-gateway-external
  to   = helm_release.istio_gateway_external
}

moved {
  from = helm_release.istio-gateway-internal
  to   = helm_release.istio_gateway_internal
}