resource "kubectl_manifest" "karpenter_node_class" {
  yaml_body = <<-YAML
    apiVersion: karpenter.k8s.aws/v1beta1
    kind: EC2NodeClass
    metadata:
      name: default
    spec:
      amiFamily: ${var.karpenter_provisioner_default_ami_family}
      blockDeviceMappings: ${jsonencode(var.karpenter_provisioner_default_block_device_mappings.specs)}
      role: ${module.karpenter[0].node_iam_role_name}
      subnetSelectorTerms:
        - tags:
            ${jsonencode(var.karpenter_node_template_default.subnetSelector)}
      securityGroupSelectorTerms:
        - tags:
            karpenter.sh/discovery: ${module.eks.cluster_name}
      tags:
        Name: "${module.eks.cluster_name}-default"
        karpenter.sh/discovery: ${module.eks.cluster_name}
  YAML

  depends_on = [
    helm_release.karpenter
  ]
}

resource "kubectl_manifest" "karpenter_node_pool_arm" {
  yaml_body = <<-YAML
    apiVersion: karpenter.sh/v1beta1
    kind: NodePool
    metadata:
      name: default-arm
    spec:
      template:
        spec:
          nodeClassRef:
            name: default
          requirements: ${jsonencode(var.karpenter_node_pool_default_arm_requirements.requirements)}
      limits:
        cpu: ${var.karpenter_nodepool_default_cpu_limits}
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
  yaml_body = <<-YAML
    apiVersion: karpenter.sh/v1beta1
    kind: NodePool
    metadata:
      name: default-amd
    spec:
      template:
        spec:
          nodeClassRef:
            name: default
          requirements: ${jsonencode(var.karpenter_node_pool_default_amd_requirements.requirements)}
      limits:
        cpu: ${var.karpenter_nodepool_default_cpu_limits}
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
