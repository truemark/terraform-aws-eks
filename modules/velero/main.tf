data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

data "aws_iam_policy" "efs_csi_driver_managed_policy" {
  arn = "arn:aws:iam::aws:policy/service-role/AmazonEFSCSIDriverPolicy"
}
data "aws_iam_policy" "ebs_csi_driver_managed_policy" {
  arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}

resource "aws_iam_policy" "velero_s3" {
  name        = "velero-s3-policy"
  description = "Policy for Velero to access S3 bucket for backups"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Effect = "Allow"
        Resource = [
          "arn:aws:s3:::${var.s3_bucket_name}",
          "arn:aws:s3:::${var.s3_bucket_name}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role" "velero" {
  name = "${var.cluster_name}-velero-role"

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
            "${var.oidc_issuer_url}:sub" = "system:serviceaccount:velero:velero"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "velero_s3" {
  policy_arn = aws_iam_policy.velero_s3.arn
  role       = aws_iam_role.velero.name
}

resource "aws_iam_role_policy_attachment" "velero_efs" {
  policy_arn = data.aws_iam_policy.efs_csi_driver_managed_policy.arn
  role       = aws_iam_role.velero.name
}

resource "aws_iam_role_policy_attachment" "velero_ebs" {
  policy_arn = data.aws_iam_policy.ebs_csi_driver_managed_policy.arn
  role       = aws_iam_role.velero.name
}

resource "kubernetes_namespace" "velero" {
  metadata {
    name = "velero"
  }
}

resource "helm_release" "velero" {
  depends_on = [
    aws_iam_policy.velero_s3
  ]
  cleanup_on_fail = true
  name            = "velero"
  namespace       = kubernetes_namespace.velero.metadata[0].name
  repository      = "https://vmware-tanzu.github.io/helm-charts"
  chart           = "velero"
  version         = var.velero_chart_version
  values = [
    <<-EOT
nodeSelector: ${jsonencode(var.critical_addons_node_selector)}
tolerations: ${jsonencode(var.critical_addons_node_tolerations)}
upgradeCRDs: true
configuration:
  backupStorageLocation:
  - name: velero
    bucket: ${var.s3_bucket_name}
    default: true
    provider: aws
    accessMode: ReadWrite
    config:
      region:  ${data.aws_region.current.name}
  volumeSnapshotLocation:
  - name: velero
    default: true
    provider: aws
    config:
      region:  ${data.aws_region.current.name}

# Set a service account so that the CRD clean up job has proper permissions to delete CRDs
serviceAccount:
  server:
    create: true
    name: velero
    annotations:
      eks.amazonaws.com/role-arn: ${aws_iam_role.velero.arn}

# Resources to Velero deployment
resources:
  requests:
    cpu: 100m
    memory: 128Mi
  limits:  ${jsonencode(var.resource_limits_velero)}

# The node-agent daemonset
deployNodeAgent: true
annotations:
  iam.amazonaws.com/role: ${aws_iam_role.velero.arn}
nodeAgent:
  # Resources to node-agent daemonset
  tolerations: ${jsonencode(var.critical_addons_node_tolerations)}
  resources:
    requests:
      cpu: 100m
      memory: 128Mi
    limits:  ${jsonencode(var.resource_limits_node_agent)}

# The kubectl upgrade/cleanup job
kubectl:
  resources:
    requests:
      cpu: 100m
      memory: 128Mi
    limits: ${jsonencode(var.resource_limits_velero)}
dnsPolicy: ClusterFirst

# Init containers to add to the Velero deployment's pod spec. At least one plugin provider image is required.
# If the value is a string then it is evaluated as a template.
initContainers:
  - name: velero-plugin-for-aws
    image: velero/velero-plugin-for-aws:v1.10.0
    imagePullPolicy: IfNotPresent
    volumeMounts:
      - mountPath: /target
        name: plugins

# Whether or not to clean up CustomResourceDefintions when deleting a release.
cleanUpCRDs: false
features: EnableCSI
backupsEnabled: true
snapshotsEnabled: true

credentials:
  # must be set to false in order to use IRSA
  useSecret: false
EOT
  ]
}
