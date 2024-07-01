output "amp_workspace_id" {
  value       = var.amp_id != null ? aws_prometheus_workspace.k8s.0.id : var.amp_id
  description = "The workspace id of the AMP used the k8s monitoring"
}
