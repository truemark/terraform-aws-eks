module "aws_efs_csi" {
  count           = var.enable_efs_csi ? 1 : 0
  source          = "./modules/aws_efs_csi"
  cluster_name    = var.cluster_name
  oidc_issuer_url = local.oidc_provider
  storage_classes = [{
    basePath              = "/eks_volumes"
    directoryPerms        = "700"
    ensureUniqueDirectory = true
    fileSystemId          = aws_efs_file_system.efs.id
    gidRangeEnd           = "2000"
    gidRangeStart         = "1000"
    name                  = "efs"
    provisioningMode      = "efs-ap"
    reuseAccessPoint      = false
    reclaim_policy        = "Delete"
  }]
  depends_on = [
    aws_eks_access_entry.access_entries,
    aws_eks_access_policy_association.access_policy_associations
  ]
}
