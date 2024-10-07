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
| <a name="provider_kubectl"></a> [kubectl](#provider\_kubectl) | ~> 1.14.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [kubectl_manifest.snapshot_controller_manifests](https://registry.terraform.io/providers/gavinbunney/kubectl/latest/docs/resources/manifest) | resource |
| [kubectl_manifest.snapshotter_manifest](https://registry.terraform.io/providers/gavinbunney/kubectl/latest/docs/resources/manifest) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_node_selector"></a> [node\_selector](#input\_node\_selector) | Config for node selector for workloads | `map(any)` | <pre>{<br>  "CriticalAddonsOnly": "true"<br>}</pre> | no |
| <a name="input_node_tolerations"></a> [node\_tolerations](#input\_node\_tolerations) | Config for node tolerations for workloads | `list(any)` | <pre>[<br>  {<br>    "effect": "NoSchedule",<br>    "key": "CriticalAddonsOnly",<br>    "operator": "Equal",<br>    "value": "true"<br>  }<br>]</pre> | no |
| <a name="input_snapshotter_version"></a> [snapshotter\_version](#input\_snapshotter\_version) | Version of external-snapshotter to install | `string` | `"v8.1.0"` | no |

## Outputs

No outputs.
<!-- END_TF_DOCS -->