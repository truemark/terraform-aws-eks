# An example of an EFS Volume that can be used in EKS cluster

resource "aws_security_group" "efs_sg" {
  name        = "${var.cluster_name}-efs-sg"
  description = "Allow NFS traffic for EFS"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 2049
    to_port         = 2049
    protocol        = "tcp"
    security_groups = [module.eks.node_security_group_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.cluster_name}-efs-sg"
  }
}

resource "aws_efs_file_system" "efs" {
  creation_token = "${var.cluster_name}-efs"
  encrypted      = true
  lifecycle_policy {
    transition_to_ia = "AFTER_30_DAYS"
  }
  tags = {
    Name = "${var.cluster_name}-efs"
  }
}

resource "aws_efs_mount_target" "efs_mount_target" {
  for_each        = toset(var.subnets_ids)
  subnet_id       = each.value
  file_system_id  = aws_efs_file_system.efs.id
  security_groups = [aws_security_group.efs_sg.id]
}

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