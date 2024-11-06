# Velero

module "velero" {
  count           = var.enable_velero ? 1 : 0
  source          = "./modules/velero"
  cluster_name    = module.eks.cluster_name
  oidc_issuer_url = local.oidc_provider
  s3_bucket_name  = var.velero_s3_bucket
  depends_on = [
    aws_eks_access_entry.access_entries,
    aws_eks_access_policy_association.access_policy_associations
  ]
}

# CSI external-snapshotter
module "external_snapshotter" {
  depends_on = [
    aws_eks_access_entry.access_entries,
    aws_eks_access_policy_association.access_policy_associations
  ]
  count               = var.enable_snapshotter ? 1 : 0
  source              = "./modules/external_snapshotter"
  snapshotter_version = "v8.1.0"
  node_selector       = var.critical_addons_node_selector
  node_tolerations    = var.critical_addons_node_tolerations
}


# Snapscheduler
module "snapscheduler" {
  depends_on = [
    module.karpenter,
    aws_eks_access_entry.access_entries,
    aws_eks_access_policy_association.access_policy_associations,
  ]
  count         = var.enable_snapscheduler && var.enable_karpenter ? 1 : 0
  source        = "./modules/snapscheduler"
  chart_version = "3.4.0"
  node_tolerations = [
    {
      key      = "karpenter.sh/nodepool"
      value    = "truemark-amd64"
      operator = "Equal"
      effect   = "NoSchedule"
    }
  ]
}
