## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 0.12.26 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 3.15 |
| <a name="requirement_kubectl"></a> [kubectl](#requirement\_kubectl) | >= 1.7.0 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | >= 2.10.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 3.15 |
| <a name="provider_aws.us-east-1"></a> [aws.us-east-1](#provider\_aws.us-east-1) | >= 3.15 |
| <a name="provider_helm"></a> [helm](#provider\_helm) | n/a |
| <a name="provider_kubectl"></a> [kubectl](#provider\_kubectl) | >= 1.7.0 |
| <a name="provider_kubernetes"></a> [kubernetes](#provider\_kubernetes) | >= 2.10.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_cert_manager"></a> [cert\_manager](#module\_cert\_manager) | github.com/truemark/terraform-aws-eks-certmanager?ref=chart | v1.13.3 |
| <a name="module_ebs_csi_irsa_role"></a> [ebs\_csi\_irsa\_role](#module\_ebs\_csi\_irsa\_role) | terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks | n/a |
| <a name="module_eks"></a> [eks](#module\_eks) | terraform-aws-modules/eks/aws | ~> 19.0 |
| <a name="module_external_secrets_irsa"></a> [external\_secrets\_irsa](#module\_external\_secrets\_irsa) | terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks | n/a |
| <a name="module_ingress_istio"></a> [ingress\_istio](#module\_ingress\_istio) | truemark/istio/kubernetes | 0.0.4 |
| <a name="module_ingress_traefik"></a> [ingress\_traefik](#module\_ingress\_traefik) | truemark/traefik/kubernetes | 0.0.1 |
| <a name="module_karpenter"></a> [karpenter](#module\_karpenter) | terraform-aws-modules/eks/aws//modules/karpenter | n/a |
| <a name="module_monitoring"></a> [monitoring](#module\_monitoring) | truemark/eks-monitoring/aws | 0.0.5 |
| <a name="module_vpc_cni_irsa"></a> [vpc\_cni\_irsa](#module\_vpc\_cni\_irsa) | terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_iam_policy.aws_load_balancer_controller](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.aws_load_balancer_controller](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.aws_load_balancer_controller](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [helm_release.aws_load_balancer_controller](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.external_secrets](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.karpenter](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [kubectl_manifest.gp2](https://registry.terraform.io/providers/gavinbunney/kubectl/latest/docs/resources/manifest) | resource |
| [kubectl_manifest.karpenter_node_class](https://registry.terraform.io/providers/gavinbunney/kubectl/latest/docs/resources/manifest) | resource |
| [kubectl_manifest.karpenter_node_pool](https://registry.terraform.io/providers/gavinbunney/kubectl/latest/docs/resources/manifest) | resource |
| [kubernetes_namespace.external_secrets](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace) | resource |
| [kubernetes_storage_class.gp3](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/storage_class) | resource |
| [kubernetes_storage_class.gp3_xfs_encrypted](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/storage_class) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_ecrpublic_authorization_token.token](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ecrpublic_authorization_token) | data source |
| [aws_eks_cluster_auth.cluster](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/eks_cluster_auth) | data source |
| [aws_iam_policy_document.aws_load_balancer_controller_full](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_roles.iam_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_roles) | data source |
| [aws_iam_roles.support_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_roles) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_alerts_sns_topics_arn"></a> [alerts\_sns\_topics\_arn](#input\_alerts\_sns\_topics\_arn) | The ARN of the SNS topic to send alerts to | `string` | `null` | no |
| <a name="input_amp_arn"></a> [amp\_arn](#input\_amp\_arn) | The AMP workspace arn | `string` | `null` | no |
| <a name="input_amp_id"></a> [amp\_id](#input\_amp\_id) | The AMP workspace id | `string` | `null` | no |
| <a name="input_cluster_additional_security_group_ids"></a> [cluster\_additional\_security\_group\_ids](#input\_cluster\_additional\_security\_group\_ids) | List of additional, externally created security group IDs to attach to the cluster control plane | `list(string)` | `[]` | no |
| <a name="input_cluster_endpoint_private_access"></a> [cluster\_endpoint\_private\_access](#input\_cluster\_endpoint\_private\_access) | Indicates whether or not the Amazon EKS private API server endpoint is enabled. | `bool` | `true` | no |
| <a name="input_cluster_endpoint_public_access"></a> [cluster\_endpoint\_public\_access](#input\_cluster\_endpoint\_public\_access) | Indicates whether or not the Amazon EKS public API server endpoint is enabled. | `bool` | `false` | no |
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | Name of the EKS cluster. | `string` | `""` | no |
| <a name="input_cluster_security_group_additional_rules"></a> [cluster\_security\_group\_additional\_rules](#input\_cluster\_security\_group\_additional\_rules) | List of additional security group rules to add to the cluster security group created. Set `source_node_security_group = true` inside rules to set the `node_security_group` as source | `any` | `{}` | no |
| <a name="input_cluster_version"></a> [cluster\_version](#input\_cluster\_version) | Kubernetes `<major>.<minor>` version to use for the EKS cluster (i.e.: `1.24`) | `string` | `"1.26"` | no |
| <a name="input_eks_managed_node_group_defaults"></a> [eks\_managed\_node\_group\_defaults](#input\_eks\_managed\_node\_group\_defaults) | Map of EKS managed node group default configurations. | `any` | `{}` | no |
| <a name="input_eks_managed_node_groups"></a> [eks\_managed\_node\_groups](#input\_eks\_managed\_node\_groups) | Map of EKS managed node group definitions to create. | `any` | `{}` | no |
| <a name="input_enable_cert_manager"></a> [enable\_cert\_manager](#input\_enable\_cert\_manager) | Enables cert-manager deployment. | `bool` | `false` | no |
| <a name="input_enable_istio"></a> [enable\_istio](#input\_enable\_istio) | Enables istio deployment | `bool` | `false` | no |
| <a name="input_enable_karpenter"></a> [enable\_karpenter](#input\_enable\_karpenter) | Add karpenter to the cluster | `bool` | `true` | no |
| <a name="input_enable_monitoring"></a> [enable\_monitoring](#input\_enable\_monitoring) | Enable monitoring | `bool` | `false` | no |
| <a name="input_enable_traefik"></a> [enable\_traefik](#input\_enable\_traefik) | Enables traefik deployment. | `bool` | `false` | no |
| <a name="input_external_secrets_kms_key_arns"></a> [external\_secrets\_kms\_key\_arns](#input\_external\_secrets\_kms\_key\_arns) | List of KMS Key ARNs that are used by Secrets Manager that contain secrets to mount using External Secrets | `list(string)` | <pre>[<br>  "arn:aws:kms:*:*:key/*"<br>]</pre> | no |
| <a name="input_external_secrets_secrets_manager_arns"></a> [external\_secrets\_secrets\_manager\_arns](#input\_external\_secrets\_secrets\_manager\_arns) | List of Secrets Manager ARNs that contain secrets to mount using External Secrets | `list(string)` | <pre>[<br>  "arn:aws:secretsmanager:*:*:secret:*"<br>]</pre> | no |
| <a name="input_external_secrets_ssm_parameter_arns"></a> [external\_secrets\_ssm\_parameter\_arns](#input\_external\_secrets\_ssm\_parameter\_arns) | List of Systems Manager Parameter ARNs that contain secrets to mount using External Secrets | `list(string)` | <pre>[<br>  "arn:aws:ssm:*:*:parameter/*"<br>]</pre> | no |
| <a name="input_iam_roles"></a> [iam\_roles](#input\_iam\_roles) | AWS IAM roles that will be mapped to RBAC roles. | `list(any)` | `[]` | no |
| <a name="input_istio_enable_external_gateway"></a> [istio\_enable\_external\_gateway](#input\_istio\_enable\_external\_gateway) | Determines whether to enable an external gateway for Istio, allowing external traffic to reach Istio services. | `bool` | `true` | no |
| <a name="input_istio_enable_internal_gateway"></a> [istio\_enable\_internal\_gateway](#input\_istio\_enable\_internal\_gateway) | Controls the enabling of an internal gateway for Istio, which manages traffic within the Kubernetes cluster. | `bool` | `false` | no |
| <a name="input_istio_external_gateway_lb_certs"></a> [istio\_external\_gateway\_lb\_certs](#input\_istio\_external\_gateway\_lb\_certs) | The certificates for the Istio external gateway load balancer. | `list(string)` | `[]` | no |
| <a name="input_istio_external_gateway_scaling_max_replicas"></a> [istio\_external\_gateway\_scaling\_max\_replicas](#input\_istio\_external\_gateway\_scaling\_max\_replicas) | The maximum number of replicas for scaling the Istio external gateway. | `number` | `5` | no |
| <a name="input_istio_external_gateway_scaling_target_cpu_utilization"></a> [istio\_external\_gateway\_scaling\_target\_cpu\_utilization](#input\_istio\_external\_gateway\_scaling\_target\_cpu\_utilization) | The target CPU utilization percentage for scaling the external gateway. | `number` | `80` | no |
| <a name="input_istio_external_gateway_service_kind"></a> [istio\_external\_gateway\_service\_kind](#input\_istio\_external\_gateway\_service\_kind) | The type of service for the Istio external gateway. | `string` | `"NodePort"` | no |
| <a name="input_istio_internal_gateway_lb_certs"></a> [istio\_internal\_gateway\_lb\_certs](#input\_istio\_internal\_gateway\_lb\_certs) | The certificates for the Istio internal gateway load balancer. | `list(string)` | `[]` | no |
| <a name="input_istio_internal_gateway_scaling_max_replicas"></a> [istio\_internal\_gateway\_scaling\_max\_replicas](#input\_istio\_internal\_gateway\_scaling\_max\_replicas) | The maximum number of replicas for scaling the Istio internal gateway. | `number` | `5` | no |
| <a name="input_istio_internal_gateway_scaling_target_cpu_utilization"></a> [istio\_internal\_gateway\_scaling\_target\_cpu\_utilization](#input\_istio\_internal\_gateway\_scaling\_target\_cpu\_utilization) | The target CPU utilization percentage for scaling the internal gateway. | `number` | `80` | no |
| <a name="input_istio_internal_gateway_service_kind"></a> [istio\_internal\_gateway\_service\_kind](#input\_istio\_internal\_gateway\_service\_kind) | The type of service for the Istio internal gateway. | `string` | `"NodePort"` | no |
| <a name="input_karpenter_node_template_default"></a> [karpenter\_node\_template\_default](#input\_karpenter\_node\_template\_default) | Config for default node template for karpenter | `map(any)` | <pre>{<br>  "subnetSelector": {<br>    "network": "private"<br>  }<br>}</pre> | no |
| <a name="input_karpenter_provisioner_default_ami_family"></a> [karpenter\_provisioner\_default\_ami\_family](#input\_karpenter\_provisioner\_default\_ami\_family) | Specifies the default Amazon Machine Image (AMI) family to be used by the Karpenter provisioner. | `string` | `"Bottlerocket"` | no |
| <a name="input_karpenter_provisioner_default_block_device_mappings"></a> [karpenter\_provisioner\_default\_block\_device\_mappings](#input\_karpenter\_provisioner\_default\_block\_device\_mappings) | Specifies the default size and characteristics of the volumes used by the Karpenter provisioner. It defines the volume size, type, and encryption settings. | `map(any)` | <pre>{<br>  "specs": [<br>    {<br>      "deviceName": "/dev/xvda",<br>      "ebs": {<br>        "encrypted": true,<br>        "volumeSize": "30Gi",<br>        "volumeType": "gp3"<br>      }<br>    },<br>    {<br>      "deviceName": "/dev/xvdb",<br>      "ebs": {<br>        "encrypted": true,<br>        "volumeSize": "100Gi",<br>        "volumeType": "gp3"<br>      }<br>    }<br>  ]<br>}</pre> | no |
| <a name="input_karpenter_provisioner_default_cpu_limits"></a> [karpenter\_provisioner\_default\_cpu\_limits](#input\_karpenter\_provisioner\_default\_cpu\_limits) | Defines the default CPU limits for the Karpenter default provisioner, ensuring resource allocation and utilization. | `number` | `300` | no |
| <a name="input_karpenter_provisioner_default_requirements"></a> [karpenter\_provisioner\_default\_requirements](#input\_karpenter\_provisioner\_default\_requirements) | Specifies the default requirements for the Karpenter provisioner template, including instance category, CPU, hypervisor, architecture, and capacity type. | `map(any)` | <pre>{<br>  "requirements": [<br>    {<br>      "key": "karpenter.k8s.aws/instance-category",<br>      "operator": "In",<br>      "values": [<br>        "m"<br>      ]<br>    },<br>    {<br>      "key": "karpenter.k8s.aws/instance-cpu",<br>      "operator": "In",<br>      "values": [<br>        "4",<br>        "8",<br>        "16"<br>      ]<br>    },<br>    {<br>      "key": "karpenter.k8s.aws/instance-hypervisor",<br>      "operator": "In",<br>      "values": [<br>        "nitro"<br>      ]<br>    },<br>    {<br>      "key": "kubernetes.io/arch",<br>      "operator": "In",<br>      "values": [<br>        "amd64"<br>      ]<br>    },<br>    {<br>      "key": "karpenter.sh/capacity-type",<br>      "operator": "In",<br>      "values": [<br>        "on-demand"<br>      ]<br>    }<br>  ]<br>}</pre> | no |
| <a name="input_karpenter_provisioner_default_ttl_after_empty"></a> [karpenter\_provisioner\_default\_ttl\_after\_empty](#input\_karpenter\_provisioner\_default\_ttl\_after\_empty) | Sets the default Time to Live (TTL) for provisioned resources by the Karpenter default provisioner after they become empty or idle. | `number` | `300` | no |
| <a name="input_karpenter_provisioner_default_ttl_until_expired"></a> [karpenter\_provisioner\_default\_ttl\_until\_expired](#input\_karpenter\_provisioner\_default\_ttl\_until\_expired) | Specifies the default Time to Live (TTL) for provisioned resources by the Karpenter default provisioner until they expire or are reclaimed. | `number` | `2592000` | no |
| <a name="input_node_security_group_additional_rules"></a> [node\_security\_group\_additional\_rules](#input\_node\_security\_group\_additional\_rules) | List of additional security group rules to add to the node security group created. Set `source_cluster_security_group = true` inside rules to set the `cluster_security_group` as source | `any` | `{}` | no |
| <a name="input_sso_roles"></a> [sso\_roles](#input\_sso\_roles) | AWS SSO roles that will be mapped to RBAC roles. | <pre>list(object({<br>    role_name = string,<br>    groups    = list(string),<br>  }))</pre> | `[]` | no |
| <a name="input_subnets_ids"></a> [subnets\_ids](#input\_subnets\_ids) | A list of subnet IDs where the nodes/node groups will be provisioned. | `list(string)` | `[]` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | A map of tags to add to all resources. | `map(string)` | `{}` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | ID of the VPC where the cluster and its nodes will be provisioned. | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_cluster_arn"></a> [cluster\_arn](#output\_cluster\_arn) | The Amazon Resource Name (ARN) of the cluster |
| <a name="output_cluster_certificate_authority_data"></a> [cluster\_certificate\_authority\_data](#output\_cluster\_certificate\_authority\_data) | Base64 encoded certificate data required to communicate with the cluster |
| <a name="output_cluster_endpoint"></a> [cluster\_endpoint](#output\_cluster\_endpoint) | Endpoint of the Kubernetes API server |
| <a name="output_cluster_iam_role_arn"></a> [cluster\_iam\_role\_arn](#output\_cluster\_iam\_role\_arn) | IAM role ARN of the EKS cluster |
| <a name="output_cluster_id"></a> [cluster\_id](#output\_cluster\_id) | The name/id of the EKS cluster. Will block on cluster creation until the cluster is really ready |
| <a name="output_cluster_identity_providers"></a> [cluster\_identity\_providers](#output\_cluster\_identity\_providers) | Map of attribute maps for all EKS identity providers enabled |
| <a name="output_cluster_oidc_issuer_url"></a> [cluster\_oidc\_issuer\_url](#output\_cluster\_oidc\_issuer\_url) | The URL on the EKS cluster for the OpenID Connect identity provider |
| <a name="output_cluster_security_group_arn"></a> [cluster\_security\_group\_arn](#output\_cluster\_security\_group\_arn) | Amazon Resource Name (ARN) of the cluster security group |
| <a name="output_cluster_security_group_id"></a> [cluster\_security\_group\_id](#output\_cluster\_security\_group\_id) | ID of the cluster security group |
| <a name="output_cluster_tls_certificate_sha1_fingerprint"></a> [cluster\_tls\_certificate\_sha1\_fingerprint](#output\_cluster\_tls\_certificate\_sha1\_fingerprint) | The SHA1 fingerprint of the public key of the cluster's certificate |
| <a name="output_custer_name"></a> [custer\_name](#output\_custer\_name) | The name of the EKS cluster |
| <a name="output_eks_managed_node_groups"></a> [eks\_managed\_node\_groups](#output\_eks\_managed\_node\_groups) | Map of attribute maps for all EKS managed node groups created |
| <a name="output_eks_managed_node_groups_autoscaling_group_names"></a> [eks\_managed\_node\_groups\_autoscaling\_group\_names](#output\_eks\_managed\_node\_groups\_autoscaling\_group\_names) | List of the autoscaling group names created by EKS managed node groups |
| <a name="output_fargate_profiles"></a> [fargate\_profiles](#output\_fargate\_profiles) | Map of attribute maps for all EKS Fargate Profiles created |
| <a name="output_node_security_group_arn"></a> [node\_security\_group\_arn](#output\_node\_security\_group\_arn) | Amazon Resource Name (ARN) of the node shared security group |
| <a name="output_node_security_group_id"></a> [node\_security\_group\_id](#output\_node\_security\_group\_id) | ID of the node shared security group |
| <a name="output_oidc_provider"></a> [oidc\_provider](#output\_oidc\_provider) | The OpenID Connect identity provider (issuer URL without leading `https://`) |
| <a name="output_oidc_provider_arn"></a> [oidc\_provider\_arn](#output\_oidc\_provider\_arn) | The ARN of the OIDC Provider if `enable_irsa = true` |
| <a name="output_self_managed_node_groups"></a> [self\_managed\_node\_groups](#output\_self\_managed\_node\_groups) | Map of attribute maps for all self managed node groups created |
| <a name="output_self_managed_node_groups_autoscaling_group_names"></a> [self\_managed\_node\_groups\_autoscaling\_group\_names](#output\_self\_managed\_node\_groups\_autoscaling\_group\_names) | List of the autoscaling group names created by self-managed node groups |
