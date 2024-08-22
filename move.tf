moved {
  from = helm_release.karpenter
  to   = helm_release.karpenter[0]
}

moved {
  from = kubectl_manifest.karpenter_node_class
  to   = kubectl_manifest.karpenter_node_class[0]
}

moved {
  from = kubectl_manifest.karpenter_node_pool_arm
  to   = kubectl_manifest.karpenter_node_pool_arm[0]
}
moved {
  from = kubectl_manifest.karpenter_node_pool_amd
  to   = kubectl_manifest.karpenter_node_pool_amd[0]
}
