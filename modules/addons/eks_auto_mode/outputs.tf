output "gitops_metadata" {
  value = { for k, v in {
    iam_role_arn              = aws_iam_role.auto_mode_node.arn
    iam_role_name             = aws_iam_role.auto_mode_node.name
    system_nodepool_manifest  = yamldecode(local.nodepool_yml)
    system_nodeclass_manifest = local.auto_mode_system_nodeclass_manifest
    } : "auto_mode_${k}" => v
  }
}
