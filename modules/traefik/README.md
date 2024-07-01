# Terraform Kubernetes Traefik Release


![Terraform](https://img.shields.io/badge/terraform-%5E0.15-green)
![Helm](https://img.shields.io/badge/helm-%5E3.0-blue)

This Terraform module simplifies the deployment of Traefik as an ingress controller in a Kubernetes cluster. It utilizes Helm charts to install Traefik with customizable configurations, allowing you to easily manage and configure Traefik for your Kubernetes environment.

## Features

- **Easy Deployment**: Deploy Traefik to your Kubernetes cluster with minimal configuration.

- **Custom Configuration**: Easily customize Traefik's configuration, including entrypoints, middleware, and more.

- **Helm Compatibility**: Utilizes Helm charts for seamless deployment and upgrades.


## Example

Here's an example of how to use this module in your Terraform configuration:

Using with your custom module
```hcl
module "ingress_route_traefik" {
  count = var.enable_traefik ? 1 : 0
  source = "truemark/traefik"
  depends_on = [module.monitoring]
}
```

Enabling with truemark EKS module
```hcl
module "eks" {
  source  = "truemark/eks/aws"
  # version = use version higher than 0.0.18

  cluster_name                    = "test-cluster"
  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = true

  vpc_id           = "vpc-xxxxxxx"
  subnets_ids      = ["subnet-xxxxxxx", "subnet-xxxxxxx", "subnet-xxxxxxx"]
  cluster_version = "1.28"
  enable_karpenter = true
  eks_managed_node_groups = {
    general = {
      disk_size      = 50
      min_size       = 1
      max_size       = 5
      desired_size   = 3
      ami_type       = "AL2_ARM_64"
      instance_types = ["m6g.large", "m6g.xlarge", "m7g.large", "m7g.xlarge", "m6g.2xlarge", "m7g.2xlarge"]
      labels = {
        "managed" : "eks"
        "purpose" : "general"
      }
      subnet_ids    = ["subnet-xxxxxxx", "subnet-xxxxxxx", "subnet-xxxxxxx"]
      capacity_type = "SPOT"
    }
  }
  enable_traefik = true ## This toggles if we want to install traefik or not
}
```



## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 0.12.26 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | >= 2.9.0 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | >= 2.10.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_helm"></a> [helm](#provider\_helm) | 2.11.0 |


## Resources

| Name | Type |
|------|------|
| [helm_release.traefik](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_kubernetes_cluster_certificate_authority_data"></a> [kubernetes\_cluster\_certificate\_authority\_data](#input\_kubernetes\_cluster\_certificate\_authority\_data) | The base64-encoded Kubernetes cluster certificate authority data. | `string` | `""` | no |
| <a name="input_kubernetes_cluster_endpoint"></a> [kubernetes\_cluster\_endpoint](#input\_kubernetes\_cluster\_endpoint) | The endpoint URL of the Kubernetes cluster. | `string` | `""` | no |
| <a name="input_kubernetes_cluster_token"></a> [kubernetes\_cluster\_token](#input\_kubernetes\_cluster\_token) | The Kubernetes API token for authentication. | `string` | `""` | no |
| <a name="input_traefik_create_namespace"></a> [traefik\_create\_namespace](#input\_traefik\_create\_namespace) | Whether to create the Traefik namespace if it doesn't exist. | `bool` | `true` | no |
| <a name="input_traefik_enabled_entrypoints"></a> [traefik\_enabled\_entrypoints](#input\_traefik\_enabled\_entrypoints) | Configuration for Traefik entrypoints. | `string` | `"ports:\n  web:\n    port: 8000\n    expose: true\n    exposedPort: 80\n    protocol: TCP\n  intWeb:\n    port: 8001\n    expose: true\n    exposedPort: 81\n    protocol: TCP\n  traefik:\n    port: 9000\n    expose: false\n    exposedPort: 9000\n    protocol: TCP\n  metrics:\n    port: 9100\n    expose: false\n    exposedPort: 9100\n    protocol: TCP\n"` | no |
| <a name="input_traefik_ingress_isDefaultClass"></a> [traefik\_ingress\_isDefaultClass](#input\_traefik\_ingress\_isDefaultClass) | Whether Traefik should be the default ingress class. | `bool` | `true` | no |
| <a name="input_traefik_release_name"></a> [traefik\_release\_name](#input\_traefik\_release\_name) | The name of the Traefik Helm release. | `string` | `"traefik"` | no |
| <a name="input_traefik_release_namespace"></a> [traefik\_release\_namespace](#input\_traefik\_release\_namespace) | The namespace where Traefik should be deployed. | `string` | `"traefik"` | no |
| <a name="input_traefik_release_version"></a> [traefik\_release\_version](#input\_traefik\_release\_version) | The version of Traefik to deploy. | `string` | `"24.0.0"` | no |

