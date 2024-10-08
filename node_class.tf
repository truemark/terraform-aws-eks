resource "kubectl_manifest" "karpenter_node_class" {
  count     = var.enable_karpenter ? 1 : 0
  yaml_body = <<-YAML
    apiVersion: karpenter.k8s.aws/v1beta1
    kind: EC2NodeClass
    metadata:
      name: truemark
    spec:
      amiFamily: ${var.truemark_nodeclass_default_ami_family}
      blockDeviceMappings: ${jsonencode(var.truemark_nodeclass_default_block_device_mappings.specs)}
      role: ${module.karpenter[0].karpenter_node_iam_role_arn}
      subnetSelectorTerms:
        - tags:
            ${jsonencode(var.karpenter_node_template_default.subnetSelector)}
      securityGroupSelectorTerms:
        - tags:
            karpenter.sh/discovery: ${module.eks.cluster_name}
      tags:
        Name: "${module.eks.cluster_name}-truemark-default"
        karpenter.sh/discovery: ${module.eks.cluster_name}
  YAML

  depends_on = [
    module.karpenter[0]
  ]
}
