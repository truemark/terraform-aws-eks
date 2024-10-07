# snapscheduler module

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~> 1.6 |
| <a name="requirement_kubectl"></a> [kubectl](#requirement\_kubectl) | ~> 1.14.0 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | ~> 2.30.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_helm"></a> [helm](#provider\_helm) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [helm_release.snapscheduler](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_chart_version"></a> [chart\_version](#input\_chart\_version) | Version of external-snapshotter to install | `string` | `"3.4.0"` | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | Namespace to install snapshotter | `string` | `"snapscheduler"` | no |
| <a name="input_node_tolerations"></a> [node\_tolerations](#input\_node\_tolerations) | Config for node tolerations for workloads | `list(any)` | <pre>[<br>  {<br>    "effect": "NoSchedule",<br>    "key": "karpenter.sh/nodepool",<br>    "operator": "Equal",<br>    "value": "truemark-amd64"<br>  }<br>]</pre> | no |

## Outputs

No outputs.
<!-- END_TF_DOCS -->

## How-to use

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: nginx-pvc
  labels:
    testlabel: testvalue
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
  storageClassName: gp3-ext4-encrypted
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
spec:
  replicas: 1
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      tolerations:
      - effect: NoSchedule
        key: karpenter.sh/nodepool
        operator: Equal
        value: truemark-amd64
      - effect: NoExecute
        key: node.kubernetes.io/not-ready
        operator: Exists
        tolerationSeconds: 300
      - effect: NoExecute
        key: node.kubernetes.io/unreachable
        operator: Exists
        tolerationSeconds: 300
      containers:
      - name: nginx
        image: nginx:latest
        ports:
        - containerPort: 80
        volumeMounts:
        - name: nginx-storage
          mountPath: /usr/share/nginx/html
      volumes:
      - name: nginx-storage
        persistentVolumeClaim:
          claimName: nginx-pvc
---
apiVersion: snapshot.storage.k8s.io/v1
kind: VolumeSnapshotClass
metadata:
  name: test-nginx-snapshotclass
driver: ebs.csi.aws.com
deletionPolicy: Delete

---
# manual snapshot
apiVersion: snapshot.storage.k8s.io/v1
kind: VolumeSnapshot
metadata:
  name: nginx-ebs-snapshot
spec:
  volumeSnapshotClassName: test-nginx-snapshotclass
  source:
    persistentVolumeClaimName: nginx-pvc

---
# scheduled snapshots
apiVersion: snapscheduler.backube/v1
kind: SnapshotSchedule
metadata:
  name: nginx-10min
  namespace: default
spec:
  claimSelector:
  disabled: false
  retention:
    expires: "1h"
    maxCount: 5
  schedule: "*/10 * * * *"
  snapshotTemplate:
    labels:
      testlabel: nginx-test-label
    snapshotClassName: test-nginx-snapshotclass
```