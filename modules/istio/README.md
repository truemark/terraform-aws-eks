# Terraform Kubernetes Istio Release


![Terraform](https://img.shields.io/badge/terraform-%5E0.15-green)
![Helm](https://img.shields.io/badge/helm-%5E3.0-blue)

This Terraform module simplifies the deployment of Istio as an ingress controller in a Kubernetes cluster. It utilizes Helm charts to install Istio with customizable configurations, allowing you to easily manage and configure Istio for your Kubernetes environment.

## Features

- **Easy Deployment**: Deploy Istio to your Kubernetes cluster with minimal configuration.

- **Custom Configuration**: Easily customize Istio's configuration.

- **Helm Compatibility**: Utilizes Helm charts for seamless deployment and upgrades.


## Example

Here's an example of how to use this module in your Terraform configuration:

Using with your custom module
```hcl
module "ingress_controller_istio" {
  count = var.enable_istio ? 1 : 0
  source = "truemark/istio"
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
  enable_istio = true ## This toggles if we want to install istio or not
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

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [helm_release.istio-base](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.istio-discovery](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.istio-gateway-external](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.istio-gateway-internal](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_istio_enable_external_gateway"></a> [istio\_enable\_external\_gateway](#input\_istio\_enable\_external\_gateway) | Determines whether to enable an external gateway for Istio, allowing external traffic to reach Istio services. | `bool` | `true` | no |
| <a name="input_istio_enable_internal_gateway"></a> [istio\_enable\_internal\_gateway](#input\_istio\_enable\_internal\_gateway) | Controls the enabling of an internal gateway for Istio, which manages traffic within the Kubernetes cluster. | `bool` | `false` | no |
| <a name="input_istio_release_namespace"></a> [istio\_release\_namespace](#input\_istio\_release\_namespace) | The Kubernetes namespace where Istio will be installed. | `string` | `"istio-system"` | no |
| <a name="input_istio_release_version"></a> [istio\_release\_version](#input\_istio\_release\_version) | The version of Istio to be installed. | `string` | `"1.18.3"` | no |

## Outputs

No outputs.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~> 1.6 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | ~> 2 |
| <a name="requirement_kubectl"></a> [kubectl](#requirement\_kubectl) | ~> 1 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | ~> 2 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |
| <a name="provider_helm"></a> [helm](#provider\_helm) | ~> 2 |
| <a name="provider_kubectl"></a> [kubectl](#provider\_kubectl) | ~> 1 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [helm_release.istio-base](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.istio-discovery](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.istio-gateway-external](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.istio-gateway-internal](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [kubectl_manifest.envoy_filters](https://registry.terraform.io/providers/gavinbunney/kubectl/latest/docs/resources/manifest) | resource |
| [aws_ec2_managed_prefix_list.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ec2_managed_prefix_list) | data source |
| [aws_subnets.istio_private_subnet_ids](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/subnets) | data source |
| [aws_subnets.istio_public_subnet_ids](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/subnets) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_aws_managed_prefix_lists"></a> [aws\_managed\_prefix\_lists](#input\_aws\_managed\_prefix\_lists) | The AWS managed prefix lists. | `map(string)` | <pre>{<br>  "cloudfront": "com.amazonaws.global.cloudfront.origin-facing"<br>}</pre> | no |
| <a name="input_istio_cluster_name"></a> [istio\_cluster\_name](#input\_istio\_cluster\_name) | The name of the cluster. | `string` | `null` | no |
| <a name="input_istio_enable_external_gateway"></a> [istio\_enable\_external\_gateway](#input\_istio\_enable\_external\_gateway) | Determines whether to enable an external gateway for Istio, allowing external traffic to reach Istio services. | `bool` | `true` | no |
| <a name="input_istio_enable_internal_gateway"></a> [istio\_enable\_internal\_gateway](#input\_istio\_enable\_internal\_gateway) | Controls the enabling of an internal gateway for Istio, which manages traffic within the Kubernetes cluster. | `bool` | `false` | no |
| <a name="input_istio_external_gateway_enable_http_port"></a> [istio\_external\_gateway\_enable\_http\_port](#input\_istio\_external\_gateway\_enable\_http\_port) | Enable http port | `bool` | `true` | no |
| <a name="input_istio_external_gateway_lb_certs"></a> [istio\_external\_gateway\_lb\_certs](#input\_istio\_external\_gateway\_lb\_certs) | The certificates for the Istio external gateway load balancer. | `list(string)` | `[]` | no |
| <a name="input_istio_external_gateway_lb_proxy_protocol"></a> [istio\_external\_gateway\_lb\_proxy\_protocol](#input\_istio\_external\_gateway\_lb\_proxy\_protocol) | Enable proxy protocol for the external gateway load balancer | `string` | `"*"` | no |
| <a name="input_istio_external_gateway_lb_source_ranges"></a> [istio\_external\_gateway\_lb\_source\_ranges](#input\_istio\_external\_gateway\_lb\_source\_ranges) | List of CIDR blocks to allow traffic from | `list(string)` | `[]` | no |
| <a name="input_istio_external_gateway_scaling_max_replicas"></a> [istio\_external\_gateway\_scaling\_max\_replicas](#input\_istio\_external\_gateway\_scaling\_max\_replicas) | The maximum number of replicas for scaling the Istio external gateway. | `number` | `5` | no |
| <a name="input_istio_external_gateway_scaling_target_cpu_utilization"></a> [istio\_external\_gateway\_scaling\_target\_cpu\_utilization](#input\_istio\_external\_gateway\_scaling\_target\_cpu\_utilization) | The target CPU utilization percentage for scaling the external gateway. | `number` | `80` | no |
| <a name="input_istio_external_gateway_service_kind"></a> [istio\_external\_gateway\_service\_kind](#input\_istio\_external\_gateway\_service\_kind) | The type of service for the Istio external gateway. | `string` | `"NodePort"` | no |
| <a name="input_istio_external_gateway_use_prefix_list"></a> [istio\_external\_gateway\_use\_prefix\_list](#input\_istio\_external\_gateway\_use\_prefix\_list) | Use prefix list for security group rules | `bool` | `false` | no |
| <a name="input_istio_internal_gateway_enable_http_port"></a> [istio\_internal\_gateway\_enable\_http\_port](#input\_istio\_internal\_gateway\_enable\_http\_port) | Enable http port | `bool` | `true` | no |
| <a name="input_istio_internal_gateway_lb_certs"></a> [istio\_internal\_gateway\_lb\_certs](#input\_istio\_internal\_gateway\_lb\_certs) | The certificates for the Istio internal gateway load balancer. | `list(string)` | `[]` | no |
| <a name="input_istio_internal_gateway_lb_proxy_protocol"></a> [istio\_internal\_gateway\_lb\_proxy\_protocol](#input\_istio\_internal\_gateway\_lb\_proxy\_protocol) | Enable proxy protocol for the external gateway load balancer | `string` | `"*"` | no |
| <a name="input_istio_internal_gateway_lb_source_ranges"></a> [istio\_internal\_gateway\_lb\_source\_ranges](#input\_istio\_internal\_gateway\_lb\_source\_ranges) | List of CIDR blocks to allow traffic from | `list(string)` | `[]` | no |
| <a name="input_istio_internal_gateway_scaling_max_replicas"></a> [istio\_internal\_gateway\_scaling\_max\_replicas](#input\_istio\_internal\_gateway\_scaling\_max\_replicas) | The maximum number of replicas for scaling the Istio internal gateway. | `number` | `5` | no |
| <a name="input_istio_internal_gateway_scaling_target_cpu_utilization"></a> [istio\_internal\_gateway\_scaling\_target\_cpu\_utilization](#input\_istio\_internal\_gateway\_scaling\_target\_cpu\_utilization) | The target CPU utilization percentage for scaling the internal gateway. | `number` | `80` | no |
| <a name="input_istio_internal_gateway_service_kind"></a> [istio\_internal\_gateway\_service\_kind](#input\_istio\_internal\_gateway\_service\_kind) | The type of service for the Istio internal gateway. | `string` | `"NodePort"` | no |
| <a name="input_istio_internal_gateway_use_prefix_list"></a> [istio\_internal\_gateway\_use\_prefix\_list](#input\_istio\_internal\_gateway\_use\_prefix\_list) | Use prefix list for security group rules | `bool` | `false` | no |
| <a name="input_istio_mesh_id"></a> [istio\_mesh\_id](#input\_istio\_mesh\_id) | The ID of the Istio mesh. | `string` | `null` | no |
| <a name="input_istio_multi_cluster"></a> [istio\_multi\_cluster](#input\_istio\_multi\_cluster) | Enable multi-cluster support for Istio. | `bool` | `false` | no |
| <a name="input_istio_network"></a> [istio\_network](#input\_istio\_network) | The network for the Istio mesh. | `string` | `null` | no |
| <a name="input_istio_nlb_tls_policy"></a> [istio\_nlb\_tls\_policy](#input\_istio\_nlb\_tls\_policy) | The TLS policy for the NLB. | `string` | `"ELBSecurityPolicy-TLS13-1-2-2021-06"` | no |
| <a name="input_istio_release_namespace"></a> [istio\_release\_namespace](#input\_istio\_release\_namespace) | The Kubernetes namespace where Istio will be installed. | `string` | `"istio-system"` | no |
| <a name="input_istio_release_version"></a> [istio\_release\_version](#input\_istio\_release\_version) | The version of Istio to be installed. | `string` | `"1.18.3"` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | The ID of the VPC. | `string` | n/a | yes |

## Outputs

No outputs.
<!-- END_TF_DOCS -->