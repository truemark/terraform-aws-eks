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
      - key: kubernetes.io/arch
        operator: In
        values: ${jsonencode(local.am_config.instance_arch)}
      - key: karpenter.sh/capacity-type
        operator: In
        values: ${jsonencode(local.am_config.instance_capacity_type)}
      - key: eks.amazonaws.com/instance-hypervisor
        operator: In
        values: ${jsonencode(local.am_config.instance_hypervisor)}
      - key: eks.amazonaws.com/instance-cpu
        operator: In
        values: ${jsonencode(local.am_config.instance_cpu)}
      - key: eks.amazonaws.com/instance-category
        operator: In
        values: ${jsonencode(local.am_config.instance_category)}
      taints:
      - effect: NoSchedule
        key: CriticalAddonsOnly
        value: true
      terminationGracePeriod: ${local.am_config.instance_termination_grace_period}
  EOF

  auto_mode_system_nodeclass_manifest = {
    apiVersion = "eks.amazonaws.com/v1"
    kind       = "NodeClass"
    metadata = {
      name = "${local.am_config.nodeclass_name}"
    }
    spec = {
      role = "${aws_iam_role.auto_mode_node.name}"
      ephemeralStorage = {
        size       = "100Gi"
        iops       = 3000
        throughput = 125
      }
      subnetSelectorTerms = [
        {
          tags = {
            network = "private"
          }
        }
      ]
      securityGroupSelectorTerms = [
        {
          tags = {
            "karpenter.sh/discovery" = "${var.addons_context.cluster_name}"
          }
        },
        {
          id = "${var.addons_context.node_security_group_id}"
        }
      ]
      tags = {
        Name                     = "${var.addons_context.cluster_name}-${local.am_config.nodeclass_name}"
        "karpenter.sh/discovery" = "${var.addons_context.cluster_name}"
      }
    }
  }
}


