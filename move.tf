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

moved {
  from = helm_release.karpenter[0]
  to   = module.karpenter[0].helm_release.karpenter
}
moved {
  from = module.karpenter[0].aws_cloudwatch_event_rule.this["health_event"]
  to   = module.karpenter[0].module.karpenter.aws_cloudwatch_event_rule.this["health_event"]
}

moved {
  from = module.karpenter[0].aws_cloudwatch_event_target.this["health_event"]
  to   = module.karpenter[0].module.karpenter.aws_cloudwatch_event_target.this["health_event"]
}

moved {
  from = module.karpenter[0].aws_iam_role_policy_attachment.controller[0]
  to   = module.karpenter[0].module.karpenter.aws_iam_role_policy_attachment.controller[0]
}

moved {
  from = module.karpenter[0].aws_sqs_queue.this[0]
  to   = module.karpenter[0].module.karpenter.aws_sqs_queue.this[0]
}

moved {
  from = module.karpenter[0].aws_iam_role_policy_attachment.node["AmazonEC2ContainerRegistryReadOnly"]
  to   = module.karpenter[0].module.karpenter.aws_iam_role_policy_attachment.node["arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"]
}

moved {
  from = module.karpenter[0].aws_iam_role_policy_attachment.node["AmazonEKSWorkerNodePolicy"]
  to   = module.karpenter[0].module.karpenter.aws_iam_role_policy_attachment.node["arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"]
}

moved {
  from = module.karpenter[0].aws_iam_role_policy_attachment.node["AmazonEKS_CNI_Policy"]
  to   = module.karpenter[0].module.karpenter.aws_iam_role_policy_attachment.node["arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"]
}

moved {
  from = module.karpenter[0].aws_iam_role_policy_attachment.node_additional["AmazonSSMManagedInstanceCore"]
  to   = module.karpenter[0].module.karpenter.aws_iam_role_policy_attachment.node_additional["AmazonSSMManagedInstanceCore"]
}

moved {
  from = module.karpenter[0].aws_iam_policy.controller[0]
  to   = module.karpenter[0].module.karpenter.aws_iam_policy.controller[0]
}

moved {
  from = module.karpenter[0].aws_eks_access_entry.node[0]
  to   = module.karpenter[0].module.karpenter.aws_eks_access_entry.node[0]
}

moved {
  from = module.karpenter[0].aws_sqs_queue_policy.this[0]
  to   = module.karpenter[0].module.karpenter.aws_sqs_queue_policy.this[0]
}

moved {
  from = module.karpenter[0].aws_iam_role.node[0]
  to   = module.karpenter[0].module.karpenter.aws_iam_role.node[0]
}

moved {
  from = module.karpenter[0].aws_cloudwatch_event_rule.this["instance_state_change"]
  to   = module.karpenter[0].module.karpenter.aws_cloudwatch_event_rule.this["instance_state_change"]
}

moved {
  from = module.karpenter[0].aws_cloudwatch_event_rule.this["instance_rebalance"]
  to   = module.karpenter[0].module.karpenter.aws_cloudwatch_event_rule.this["instance_rebalance"]
}

moved {
  from = module.karpenter[0].aws_iam_role.controller[0]
  to   = module.karpenter[0].module.karpenter.aws_iam_role.controller[0]
}

moved {
  from = module.karpenter[0].aws_cloudwatch_event_rule.this["spot_interrupt"]
  to   = module.karpenter[0].module.karpenter.aws_cloudwatch_event_rule.this["spot_interupt"]
}

moved {
  from = module.karpenter[0].aws_cloudwatch_event_target.this["spot_interrupt"]
  to   = module.karpenter[0].module.karpenter.aws_cloudwatch_event_target.this["spot_interupt"]
}

moved {
  from = module.karpenter[0].aws_cloudwatch_event_target.this["instance_rebalance"]
  to   = module.karpenter[0].module.karpenter.aws_cloudwatch_event_target.this["instance_rebalance"]
}

moved {
  from = module.karpenter[0].aws_cloudwatch_event_target.this["instance_state_change"]
  to   = module.karpenter[0].module.karpenter.aws_cloudwatch_event_target.this["instance_state_change"]
}
