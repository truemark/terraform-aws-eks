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

# "metadata":
#   "labels":
#     "CriticalAddonsOnly": "true"
#   "name": "truemark-system"
# "spec":
#   "disruption":
#     "budgets":
#     - "nodes": "10%"
#     "consolidateAfter": "0s"
#     "consolidationPolicy": "WhenEmptyOrUnderutilized"
#   "limits":
#     "cpu": "64"
#     "memory": "64Gi"
#   "template":
#     "spec":
#       "expireAfter": "480h"
#       "nodeClassRef":
#         "group": "eks.amazonaws.com"
#         "kind": "NodeClass"
#         "name": "truemark-system"
#       "requirements":
#       - "key": "karpenter.sh/capacity-type"
#         "operator": "In"
#         "values":
#         - "spot"
#       - "key": "eks.amazonaws.com/instance-category"
#         "operator": "In"
#         "values":
#         - "c"
#         - "m"
#         - "r"
#       - "key": "eks.amazonaws.com/instance-generation"
#         "operator": "Gt"
#         "values": "4"
#       - "key": "kubernetes.io/arch"
#         "operator": "In"
#         "values":
#         - "amd64"
#       - "key": "eks.amazonaws.com/instance-cpu"
#         "operator": "In"
#         "values":
#         - "2"
#         - "4"
#         - "8"
#       - "key": "eks.amazonaws.com/instance-hypervisor"
#         "operator": "In"
#         "values":
#         - "nitro"
#       "taints":
#       - "effect": "NoSchedule"
#         "key": "CriticalAddonsOnly"
#         "value": "true"
#       "terminationGracePeriod": "24h0m0s"