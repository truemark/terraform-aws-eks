data "aws_caller_identity" "current" {}

resource "helm_release" "efs_csi_driver" {
  chart      = var.chart_name
  name       = var.release_name
  version    = var.chart_version
  repository = var.helm_repo_name
  namespace  = "kube-system"
  set {
    name  = "controller.serviceAccount.create"
    value = "false"
  }
  set {
    name  = "controller.serviceAccount.name"
    value = "efs-csi-controller-sa"
  }
  set {
    name  = "controller.replicaCount"
    value = "2"
  }
  depends_on = [
    kubernetes_service_account.efs_csi_driver_sa,
    aws_iam_role_policy_attachment.efs_csi_policy_attach
  ]
}

data "aws_iam_policy" "efs_csi_driver_managed_policy" {
  arn = "arn:aws:iam::aws:policy/service-role/AmazonEFSCSIDriverPolicy"
}

resource "aws_iam_role" "efs_csi_driver_role" {
  name = "${var.cluster_name}-efs-csi-driver-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Principal = {
          Federated = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${var.oidc_issuer_url}"
        }
        Condition = {
          StringEquals = {
            "${var.oidc_issuer_url}:aud" = "sts.amazonaws.com",
            "${var.oidc_issuer_url}:sub" = "system:serviceaccount:kube-system:efs-csi-controller-sa"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "efs_csi_policy_attach" {
  policy_arn = data.aws_iam_policy.efs_csi_driver_managed_policy.arn
  role       = aws_iam_role.efs_csi_driver_role.name
}

resource "kubernetes_service_account" "efs_csi_driver_sa" {
  metadata {
    name      = "efs-csi-controller-sa"
    namespace = "kube-system"
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.efs_csi_driver_role.arn
    }
  }
  automount_service_account_token = true
}

resource "kubernetes_storage_class" "efs_sc" {
  for_each            = { for sc in var.storage_classes : sc.name => sc }
  storage_provisioner = "efs.csi.aws.com"
  metadata {
    name = each.value.name
  }
  parameters = {
    provisioningMode      = each.value.provisioningMode
    fileSystemId          = each.value.fileSystemId
    directoryPerms        = each.value.directoryPerms
    basePath              = each.value.basePath
    ensureUniqueDirectory = tostring(each.value.ensureUniqueDirectory)
    reuseAccessPoint      = tostring(each.value.reuseAccessPoint)
    gidRangeStart         = each.value.gidRangeStart
    gidRangeEnd           = each.value.gidRangeEnd
  }
  reclaim_policy = each.value.reclaim_policy
  depends_on     = [helm_release.efs_csi_driver]
}
