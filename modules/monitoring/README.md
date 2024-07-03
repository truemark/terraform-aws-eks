## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~> 1.6 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 5.0 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | ~> 2.9.0 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | ~> 2.10.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | ~> 5.0 |
| <a name="provider_helm"></a> [helm](#provider\_helm) | ~> 2.9.0 |
| <a name="provider_kubernetes"></a> [kubernetes](#provider\_kubernetes) | ~> 2.10.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_amp_irsa_role"></a> [amp\_irsa\_role](#module\_amp\_irsa\_role) | terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_prometheus_alert_manager_definition.k8s](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/prometheus_alert_manager_definition) | resource |
| [aws_prometheus_rule_group_namespace.k8s](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/prometheus_rule_group_namespace) | resource |
| [aws_prometheus_workspace.k8s](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/prometheus_workspace) | resource |
| [helm_release.prometheus_install](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [kubernetes_namespace.prometheus](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_alert_role_arn"></a> [alert\_role\_arn](#input\_alert\_role\_arn) | The ARN of the role to assume when sending alerts to SNS | `string` | `null` | no |
| <a name="input_alerts_sns_topics_arn"></a> [alerts\_sns\_topics\_arn](#input\_alerts\_sns\_topics\_arn) | The ARN of the SNS topic to send alerts to | `string` | n/a | yes |
| <a name="input_amp_alerting_rules_exclude_namespace"></a> [amp\_alerting\_rules\_exclude\_namespace](#input\_amp\_alerting\_rules\_exclude\_namespace) | Apply exclusion of namespace pattern defined | `string` | `""` | no |
| <a name="input_amp_arn"></a> [amp\_arn](#input\_amp\_arn) | The AMP workspace arn | `string` | `null` | no |
| <a name="input_amp_custom_alerting_rules"></a> [amp\_custom\_alerting\_rules](#input\_amp\_custom\_alerting\_rules) | Prometheus K8s custom alerting rules | `string` | `""` | no |
| <a name="input_amp_id"></a> [amp\_id](#input\_amp\_id) | The AMP workspace id | `string` | `null` | no |
| <a name="input_amp_name"></a> [amp\_name](#input\_amp\_name) | The AMP workspace name | `string` | `null` | no |
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | Name of the EKS cluster. | `string` | n/a | yes |
| <a name="input_cluster_oidc_issuer_url"></a> [cluster\_oidc\_issuer\_url](#input\_cluster\_oidc\_issuer\_url) | The URL on the EKS cluster for the OpenID Connect identity provider | `string` | n/a | yes |
| <a name="input_enable_alerts"></a> [enable\_alerts](#input\_enable\_alerts) | Enable alerts | `bool` | `true` | no |
| <a name="input_monitoring_stack_enable_alertmanager"></a> [monitoring\_stack\_enable\_alertmanager](#input\_monitoring\_stack\_enable\_alertmanager) | Enable on cluster alertmanager | `bool` | `false` | no |
| <a name="input_monitoring_stack_enable_pushgateway"></a> [monitoring\_stack\_enable\_pushgateway](#input\_monitoring\_stack\_enable\_pushgateway) | Enable on cluster alertmanager | `bool` | `false` | no |
| <a name="input_oidc_provider_arn"></a> [oidc\_provider\_arn](#input\_oidc\_provider\_arn) | The ARN of the OIDC Provider if `enable_irsa = true` | `string` | n/a | yes |
| <a name="input_prometheus_node_selector"></a> [prometheus\_node\_selector](#input\_prometheus\_node\_selector) | K8S node selector for prometheus | `map(any)` | <pre>{<br>  "nodeSelector": {}<br>}</pre> | no |
| <a name="input_prometheus_node_tolerations"></a> [prometheus\_node\_tolerations](#input\_prometheus\_node\_tolerations) | K8S node tolerations for prometheus | `map(any)` | <pre>{<br>  "tolerations": []<br>}</pre> | no |
| <a name="input_prometheus_pvc_storage_size"></a> [prometheus\_pvc\_storage\_size](#input\_prometheus\_pvc\_storage\_size) | Disk size for prometheus data storage | `string` | `"30Gi"` | no |
| <a name="input_prometheus_server_data_volume_size"></a> [prometheus\_server\_data\_volume\_size](#input\_prometheus\_server\_data\_volume\_size) | Volume size for prometheus data | `string` | `"150Gi"` | no |
| <a name="input_prometheus_server_request_memory"></a> [prometheus\_server\_request\_memory](#input\_prometheus\_server\_request\_memory) | Requested memory for prometheus instance | `string` | `"4Gi"` | no |
| <a name="input_region"></a> [region](#input\_region) | The AWS region to deploy to. | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | A map of tags to add to all resources. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_amp_workspace_id"></a> [amp\_workspace\_id](#output\_amp\_workspace\_id) | The workspace id of the AMP used the k8s monitoring |
