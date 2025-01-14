locals {
  nodepool_yml = <<EOF
apiVersion: karpenter.sh/v1
kind: NodePool
metadata:
  labels:
    CriticalAddonsOnly: true
  name: "${local.am_config.nodepool_name}"
spec:
  disruption:
    budgets:
    - nodes: 10%
    consolidateAfter: 0s
    consolidationPolicy: WhenEmptyOrUnderutilized
  template:
    spec:
      expireAfter: ${local.am_config.instance_expire_after}
      nodeClassRef:
        group: eks.amazonaws.com
        kind: NodeClass
        name: ${local.am_config.nodeclass_name}
      requirements:
      - key: eks.amazonaws.com/instance-category
        operator: In
        values:  ${jsonencode(local.am_config.instance_category)}
      - key: karpenter.sh/capacity-type
        operator: In
        values: ${jsonencode(local.am_config.instance_capacity_type)}
      taints:
      - effect: NoSchedule
        key: CriticalAddonsOnly
        value: true
      terminationGracePeriod: ${local.am_config.instance_termination_grace_period}
  EOF
}
