# This YAML file shows how to deploy the snapshot controller

# The snapshot controller implements the control loop for CSI snapshot functionality.
# It should be installed as part of the base Kubernetes distribution in an appropriate
# namespace for components implementing base system functionality. For installing with
# Vanilla Kubernetes, kube-system makes sense for the namespace.

---
kind: Deployment
apiVersion: apps/v1
metadata:
  name: snapshot-controller
  namespace: kube-system
spec:
  replicas: 2
  selector:
    matchLabels:
      app.kubernetes.io/name: snapshot-controller
  # The snapshot controller won't be marked as ready if the v1 CRDs are unavailable.
  # The flag --retry-crd-interval-max is used to determine how long the controller
  # will wait for the CRDs to become available before exiting. The default is 30 seconds
  # so minReadySeconds should be set slightly higher than the flag value.
  minReadySeconds: 35
  strategy:
    rollingUpdate:
      maxSurge: 0
      maxUnavailable: 1
    type: RollingUpdate
  template:
    metadata:
      labels:
        app.kubernetes.io/name: snapshot-controller
    spec:
      serviceAccountName: snapshot-controller
      # nodeSelector: ${node_selector}
      # tolerations: ${node_tolerations}
      tolerations:
      - effect: NoSchedule
        key: CriticalAddonsOnly
        operator: Equal
        value: "true"
      containers:
        - name: snapshot-controller
          image: registry.k8s.io/sig-storage/snapshot-controller:v8.0.1
          # image: "${snapshotter_image}"
          args:
            - "--v=5"
            - "--leader-election=true"
            # Add a marker to the snapshot-controller manifests. This is needed to enable feature gates in CSI prow jobs.
            # For example, in https://github.com/kubernetes-csi/csi-release-tools/pull/209, the snapshot-controller YAML is updated to add --prevent-volume-mode-conversion=true so that the feature can be enabled for certain e2e tests.
            # end snapshot controller args
          imagePullPolicy: IfNotPresent
