resource "kubectl_manifest" "karpenter_node_pool_arm" {
  count     = var.enable_karpenter ? 1 : 0
  yaml_body = <<-YAML
    apiVersion: karpenter.sh/v1
    kind: NodePool
    metadata:
      name: truemark-arm64
    spec:
      disruption:
        budgets:
          - nodes: 10%
        consolidationPolicy: WhenUnderutilized
        expireAfter: 720h
      template:
        spec:
          nodeClassRef:
            name: truemark
          taints:
          - key: karpenter.sh/nodepool
            value: "truemark-arm64"
            effect: NoSchedule
          requirements: ${jsonencode(var.karpenter_node_pool_default_arm_requirements.requirements)}
      disruption:
        expireAfter: ${var.karpenter_nodepool_default_expireAfter}
        consolidationPolicy: WhenEmpty
        consolidateAfter: 30s
      weight: ${var.karpenter_arm_node_pool_weight}
  YAML

  depends_on = [
    kubectl_manifest.karpenter_node_class
  ]
}

resource "kubectl_manifest" "karpenter_node_pool_amd" {
  count     = var.enable_karpenter ? 1 : 0
  yaml_body = <<-YAML
    apiVersion: karpenter.sh/v1
    kind: NodePool
    metadata:
      name: truemark-amd64
    spec:
      disruption:
        budgets:
          - nodes: 10%
        consolidationPolicy: WhenUnderutilized
        expireAfter: 720h
      template:
        spec:
          nodeClassRef:
            name: truemark
          taints:
          - key: karpenter.sh/nodepool
            value: "truemark-amd64"
            effect: NoSchedule
          requirements: ${jsonencode(var.karpenter_node_pool_default_amd_requirements.requirements)}
      disruption:
        expireAfter: ${var.karpenter_nodepool_default_expireAfter}
        consolidationPolicy: WhenEmpty
        consolidateAfter: 30s
      weight: ${var.karpenter_amd_node_pool_weight}
  YAML

  depends_on = [
    kubectl_manifest.karpenter_node_class
  ]
}
