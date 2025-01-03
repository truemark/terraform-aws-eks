# EKS + Karpenter Node Pools design

## Proposal Overview
This document outlines a robust and cost-efficient workflow for managing Kubernetes workloads on EKS with Karpenter. The focus is on supporting ARM64 and AMD64 workloads, with the default pool being AMD64 using spot instances. It also includes dedicated pools for burstable batch and cron jobs to prevent interference with default workloads.

---

## Architecture Design

### Cluster with Karpenter

1. **Default AMD64 Spot Pool**:
    - General-purpose workloads using spot instances
    - Primary pool for RND, work in progress, test and temporary workloads.
    - Configured to use spot instances for cost efficiency.
    - Lowest weight for node pool
2. **ARM64 Spot Pool**:
   - Same as above for ARM-based workloads.
2. **AMD64 and ARM64 TrueMark NodePools**:
   - For planned, budgeted and predictable workloads running on on-demand nodes
   - Workloads need to have tolerations to run in this pool
   - Pools have higher weight comparing to default ones
3. **AMD64 Batch/Cron Pool**:
   - Isolated pool for batch and cron jobs.
   - Prevents these workloads from interfering with default workloads.
   - Uses Spot  instance if applicable
4. **ARM64 Batch/Cron Pool**:
   - Same as above but for ARM-based batch/cron jobs.

```bash
+----------------------------+      +-----------------------------+
| EKS Control Plane          |      | Managed Node Pools          |
|                            |      |                             |
| +----------------------+   |      | +-------------------------+ |
| | Karpenter Controller |---|----->| | AMD64 TrueMark Pool     | |
| +----------------------+   |      | +-------------------------+ |
|                            |      | +-------------------------+ |
|                            |      | | ARM64 TrueMark Pool     | |
|                            |      | +-------------------------+ |
|                            |      | |      (Optional)         | |
|                            |      | +-------------------------+ |
|                            |      | |    Spot Node Pools      | |
|                            |      | +-------------------------+ |
|                            |      | +-------------------------+ |
|                            |      | | Batch/Cron Job Spot Pool| |
|                            |      | +-------------------------+ |
|                            |      +-----------------------------+
|                            |      +-----------------------------+
|                            |      | Managed Node Groups         |
|                            |      |                             |
| +----------------------+   |      | +-------------------------+ |
| | Managed Node Groups  |---|----->| | Critical Addons ASG     | |
| +----------------------+   |      | +-------------------------+ |
+----------------------------+      +-----------------------------+
```


### Cluster with Auto-Mode

In Auto-mode, the cluster automatically adjusts the node pools based on the workload requirements and predefined policies. This mode leverages Karpenter's capabilities to dynamically provision and de-provision nodes, ensuring optimal resource utilization and cost efficiency. The Auto-mode configuration includes:

- **Dynamic Scaling**: Automatically scales the node pools up or down based on real-time workload demands.
- **Policy-Driven Provisioning**: Uses predefined policies to determine the type and size of nodes to be provisioned.
- **Cost Optimization**: Prioritizes the use of spot instances for cost savings while ensuring availability for critical workloads.
- **Workload Segmentation**: Segregates workloads into different node pools to prevent resource contention and ensure performance isolation.
- **Support for ARM64 and AMD64**: Provides seamless support for both ARM64 and AMD64 architectures, allowing for diverse workload deployments.

By default Auto mode provide 2 node pools - for Critical Addons and General Amd64 node pool.
TrueMark's implementation adds dedicated pools of on-demand amd64 and arm64 nodes. It is also possible to extend it with additional pools.

1. **Critical Addons Pool**:
  - Dedicated pool for critical system workloads.
  - Ensures high availability and reliability for essential services.
  - Configured to use on-demand instances for stability.
  - Highest priority and weight among node pools.

2. **General AMD64 Node Pool**:
  - General-purpose workloads using AMD64 architecture.
  - Suitable for RND, work in progress, test, and temporary workloads.
  - Lower priority compared to other pools.

3. **AMD64 and ARM64 TrueMark NodePools**:
  - For planned and predictable workloads running on on-demand nodes.
  - Ensures stability and performance for important applications.
  - Workloads need to have tolerations to run in this pool.
  - Higher priority and weight compared to general-purpose pools.

Additional use cases for customer managed node pools can be
1. **Batch/Cron Job Pools**:
  - Isolated pools for batch and cron jobs.
  - Prevent these workloads from interfering with default workloads.
  - Can use spot instances if applicable.
2. **AMD64/ARM64 Spot Instances Pool**:
  - Pools for ARM64 and AMD64 spot instances.
  - Suitable for workloads that can tolerate interruptions, test or work-in-progress workloads
  - Configured to maximize cost efficiency.

```bash
+----------------------------+      +-----------------------------+
| EKS Control Plane          |      | Managed Node Pools          |
|                            |      |                             |
| +----------------------+   |      | +-------------------------+ |
| | Karpenter Controller |---|----->| | AMD64 System Pool       | |
| +----------------------+   |      | +-------------------------+ |
|                            |      | +-------------------------+ |
|                            |      | | AMD64 TrueMark Pool     | |
|                            |      | +-------------------------+ |
|                            |      | +-------------------------+ |
|                            |      | | ARM64 TrueMark Pool     | |
|                            |      | +-------------------------+ |
|                            |      | |      (Optional)         | |
|                            |      | +-------------------------+ |
|                            |      | |    Spot Node Pools      | |
|                            |      | +-------------------------+ |
|                            |      | +-------------------------+ |
|                            |      | | Batch/Cron Job Spot Pool| |
|                            |      | +-------------------------+ |
+----------------------------+      +-----------------------------+
```

### Cluster with Cast AI

TBD

### Node Pool Segmentation

## Benefits

1.	Cost Efficiency: Ensures spot instance utilization.
2.	Workload Isolation: Ensures batch and cron jobs do not disrupt other workloads.
3.	Scalability: Automatically adapts to workload demands.
4.	Architecture Flexibility: Supports both ARM64 and AMD64 workloads seamlessly.

---

## Monitoring and Alerting

Karpenter metrics: <https://karpenter.sh/docs/reference/metrics/>

### Key Metrics to Monitor
1. **CPU Utilization**: Threshold > 80%.
2. **Memory Utilization**: Threshold > 75%.
3. **Pending Pods**:

### Tools
1. **Prometheus**: Collect Kubernetes and Karpenter metrics.
2. **Grafana**: Visualize workload distribution and utilization.
3. **AWS Cost Explorer**: Track costs by node pool and workload type.
4. **Kubecost**: Detailed Kubernetes-native cost breakdowns.

### Example Prometheus Queries
#### CPU Utilization
```promql
sum(rate(node_cpu_seconds_total{nodepool="amd64-default"}[5m]))
/
sum(machine_cpu_cores{nodepool="amd64-default"})
```

#### Memory Utilization Query
```promql
sum(node_memory_MemTotal_bytes{nodepool="amd64-default"})
-
sum(node_memory_MemAvailable_bytes{nodepool="amd64-default"})
/
sum(node_memory_MemTotal_bytes{nodepool="amd64-default"})
```

### Pending Pods Query

```promql
count(kube_pod_status_unscheduled{nodepool="amd64-default"})
```


## Testing

Below is a test inflate workflow that can trigger nodes provisioning with Karpenter

```yml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: inflate
spec:
  replicas: 3
  selector:
    matchLabels:
      app: inflate
  template:
    metadata:
      labels:
        app: inflate
    spec:
      # nodeSelector:
        # intent: apps
      containers:
        - name: inflate
          image: public.ecr.aws/eks-distro/kubernetes/pause:3.2
          resources:
            requests:
              cpu: "0,5"
              memory: 1Gi
            limits:
              cpu: "0,5"
              memory: 1Gi
```