locals {
  # Manifests come from
  # https://raw.githubusercontent.com/kubernetes-csi/external-snapshotter/v8.1.0/client/config/crd/snapshot.storage.k8s.io_volumesnapshotclasses.yaml
  # https://raw.githubusercontent.com/kubernetes-csi/external-snapshotter/v8.1.0/client/config/crd/snapshot.storage.k8s.io_volumesnapshotcontents.yaml
  # https://raw.githubusercontent.com/kubernetes-csi/external-snapshotter/v8.1.0/client/config/crd/snapshot.storage.k8s.io_volumesnapshots.yaml
  # https://raw.githubusercontent.com/kubernetes-csi/external-snapshotter/v8.1.0/deploy/kubernetes/snapshot-controller/rbac-snapshot-controller.yaml
  # https://raw.githubusercontent.com/kubernetes-csi/external-snapshotter/v8.1.0/deploy/kubernetes/snapshot-controller/setup-snapshot-controller.yaml
  kube_mainifests = [
    "rbac-snapshot-controller-clusterrole.yaml",
    "rbac-snapshot-controller-crb.yaml",
    "rbac-snapshot-controller-role-binding.yaml",
    "rbac-snapshot-controller-role.yaml",
    "rbac-snapshot-controller-sa.yaml",
    "snapshot.storage.k8s.io_volumesnapshotclasses.yaml",
    "snapshot.storage.k8s.io_volumesnapshotcontents.yaml",
    "snapshot.storage.k8s.io_volumesnapshots.yaml"
  ]
}

resource "kubectl_manifest" "snapshot_controller_manifests" {
  for_each  = toset(local.kube_mainifests)
  yaml_body = file("${path.module}/manifests/${each.value}")
}

resource "kubectl_manifest" "snapshotter_manifest" {
  depends_on = [kubectl_manifest.snapshot_controller_manifests]
  yaml_body = templatefile("${path.module}/manifests/snapshot-controller.tpl", {
    node_selector     = jsonencode(var.node_selector)
    node_tolerations  = jsonencode(var.node_tolerations)
    snapshotter_image = "registry.k8s.io/sig-storage/snapshot-controller:v8.0.1"
  })
}
