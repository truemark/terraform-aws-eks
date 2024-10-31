
## Backup and Restore Options for EKS Clusters Using Velero, CSI External Snapshotter, and SnapScheduler 

### 1. Overview

This guide details the setup and usage of **Velero**, **CSI External Snapshotter**, and **SnapScheduler** for reliable backup and restore operations in Kubernetes clusters. This strategy focuses on protecting application and persistent volume data against various failure scenarios.

### 2. Prerequisites

1. **Kubernetes Cluster** deployed from this repository.
2. **Cluster Administrator Access** to install Custom Resource Definitions (CRDs) and configure permissions.
3. **Access to an S3 Bucket** (for Velero backups): Configure bucket access for Velero. It's recommended to deploy the bucket as a separate Terraform configuration to maintain an independent lifecycle.

### 3. Velero Installation and Setup

#### Step-by-Step Guide

1. **Downloading and Installing Velero CLI**:
    ```bash
    curl -L https://github.com/vmware-tanzu/velero/releases/download/<version>/velero-<version>-linux-amd64.tar.gz -o velero.tar.gz
    tar -xvf velero.tar.gz -C /usr/local/bin
    ```

2. **Configure Velero Using Terraform**:

   Enable Velero with the Terraform module in this repository by setting the `enable_velero` variable to `true`.

    ```tf
    module "velero" {
      count           = var.enable_velero ? 1 : 0
      source          = "./modules/velero"
      cluster_name    = module.eks.cluster_name
      oidc_issuer_url = local.oidc_provider
      s3_bucket_name  = aws_s3_bucket.velero.id
      depends_on      = [
          aws_eks_access_entry.access_entries,
          aws_eks_access_policy_association.access_policy_associations
      ]
    }
    ```

3. **Verify Installation**:
    ```bash
    kubectl get deployments -n velero
    ```

#### Using Velero to Manually Backup and Restore Volume Resources

- **Create a Backup**:
  ```bash
  velero backup create prometheus --include-namespaces prometheus
  ```

- **Check Backup Status**:
  ```bash
  velero backup describe prometheus --details
  ```

   View the resulting snapshots in AWS:
   ```bash
   aws ec2 describe-snapshots \
     --query 'Snapshots[*].[SnapshotId, StartTime, Tags[?Key==`Name`].Value | [0]]' \
     --owner-ids self \
     --output text
   ```

- **Restore from Backup**:
  
   If the Prometheus namespace and associated resources have been deleted, restore them with:
   ```bash
   velero restore create --from-backup prometheus --include-resources persistentvolumes,persistentvolumeclaims,namespaces
   ```

   After restoration, import any re-created resources into Terraform to maintain synchronization:
   ```bash
   terraform import 'module.eks.module.monitoring[0].kubernetes_namespace.prometheus' prometheus
   ```

#### Using Velero Schedules for Automated Backups

Velero’s `Schedule` objects allow creating Cron-like schedules for automated backups.

```yaml
apiVersion: velero.io/v1
kind: Schedule
metadata:
  name: weekly-full-cluster-backup
  namespace: velero
spec:
  schedule: "0 1 * * 0"  # Runs weekly on Sunday at 1:00 AM
  template:
    includedNamespaces: []  # Empty means backup all namespaces
    storageLocation: <backup-location-name>
    ttl: 720h  # Retains backup for 30 days (720 hours)
```

### 4. Configuring CSI External Snapshotter

The **CSI External Snapshotter** provides volume snapshots for Persistent Volume Claim (PVC) backup. Configure it with Terraform as shown:

```tf
module "external_snapshotter" {
  source              = "./modules/external_snapshotter"
  count               = var.enable_snapshotter ? 1 : 0
  snapshotter_version = "v8.1.0"
  depends_on          = [
      aws_eks_access_entry.access_entries,
      aws_eks_access_policy_association.access_policy_associations
  ]
  node_selector       = var.critical_addons_node_selector
  node_tolerations    = var.critical_addons_node_tolerations
}
```

### 5. SnapScheduler Setup

**SnapScheduler** automates snapshots, enhancing resilience through periodic PVC backups. Note: **Karpenter** is required for x86 architecture compatibility.

```tf
module "snapscheduler" {
  depends_on          = [module.karpenter, aws_eks_access_entry.access_entries]
  count               = var.enable_snapscheduler && var.enable_karpenter ? 1 : 0
  source              = "./modules/snapscheduler"
  chart_version       = "3.4.0"
  node_tolerations    = [{ key = "karpenter.sh/nodepool", value = "truemark-amd64", operator = "Equal", effect = "NoSchedule" }]
}
```

2. **Schedule Snapshots**:
Create a configuration to automate snapshotting:

```yaml
apiVersion: snapscheduler.io/v1
kind: SnapScheduler
metadata:
  name: pvc-snapshot-scheduler
spec:
  schedule: "0 2 * * *"  # Runs daily at 2:00 AM
  retentionCount: 7
  volumeSnapshotClassName: csi-snapclass
  pvcSelector:
    matchLabels:
      backup: true
```

---

### 6. Conclusion

This guide equips you to manage reliable backup and restore operations for EKS, using Velero, CSI External Snapshotter, and SnapScheduler. By integrating these practices, you’ll ensure data resilience and a robust disaster recovery strategy for your Kubernetes environment.

### 7. References

- [Velero Backup Reference](https://velero.io/docs/v1.15/backup-reference/)
- [SnapScheduler Usage Guide](https://backube.github.io/snapscheduler/usage.html)
