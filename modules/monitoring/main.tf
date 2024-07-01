locals {
  oidc_provider            = replace(var.cluster_oidc_issuer_url, "https://", "")
  iamproxy_service_account = "amp-iamproxy-service-account"
}

module "amp_irsa_role" {
  source = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"

  role_name = "${var.cluster_name}-EKSAMPServiceAccountRole"

  attach_amazon_managed_service_prometheus_policy  = true
  amazon_managed_service_prometheus_workspace_arns = [var.amp_name != null ? aws_prometheus_workspace.k8s.0.arn : var.amp_arn]

  oidc_providers = {
    main = {
      provider_arn               = var.oidc_provider_arn
      namespace_service_accounts = ["prometheus:${local.iamproxy_service_account}"]
    }
  }

  tags = var.tags
}

resource "kubernetes_namespace" "prometheus" {
  metadata {
    name = "prometheus"
  }
}

resource "helm_release" "prometheus_install" {
  name       = "prometheus"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "prometheus"
  namespace  = kubernetes_namespace.prometheus.metadata[0].name

  set {
    name  = "serviceAccounts.server.annotations.eks\\.amazonaws\\.com/role-arn"
    value = module.amp_irsa_role.iam_role_arn
    type  = "string"
  }
  set {
    name  = "serviceAccounts.server.name"
    value = local.iamproxy_service_account
    type  = "string"
  }
  set {
    name  = "alertmanager.enabled"
    value = false
  }
  set {
    name  = "prometheus-pushgateway.enabled"
    value = false
  }
  set {
    name  = "server.remoteWrite[0].url"
    value = "https://aps-workspaces.${var.region}.amazonaws.com/workspaces/${var.amp_name != null ? aws_prometheus_workspace.k8s.0.id : var.amp_id}/api/v1/remote_write"
    type  = "string"
  }
  set {
    name  = "server.remoteWrite[0].sigv4.region"
    value = var.region
    type  = "string"
  }
  set {
    name  = "server.remoteWrite[0].queue_config.max_samples_per_send"
    value = 1000
  }
  set {
    name  = "server.remoteWrite[0].queue_config.max_shards"
    value = 200
  }
  set {
    name  = "server.remoteWrite[0].queue_config.capacity"
    value = 2500
  }

  set {
    name  = "server.resources.requests.memory"
    value = var.prometheus_server_request_memory
  }

  set {
    name  = "server.persistentVolume.size"
    value = var.prometheus_server_data_volume_size
  }

  set {
    name  = "server.tolerations"
    value = jsonencode(var.prometheus_node_tolerations)
  }

  timeout = 600
}

resource "aws_prometheus_workspace" "k8s" {
  count = var.amp_name != null ? 1 : 0

  alias = var.amp_name

  tags = var.tags
}

resource "aws_prometheus_alert_manager_definition" "k8s" {
  count = var.enable_alerts ? 1 : 0

  workspace_id = var.amp_name != null ? aws_prometheus_workspace.k8s.0.id : var.amp_id
  definition   = <<EOF
template_files:
  default_template: |
    {{ define "sns.default.message" }}{"receiver":"{{ .Receiver }}","source":"prometheus","status":"{{ .Status }}","alerts":[{{ range $alertIndex, $alerts := .Alerts }}{{ if $alertIndex }},{{ end }}{"status":"{{ $alerts.Status }}",{{ if gt (len $alerts.Labels.SortedPairs) 0 }}"labels":{{ "{" }}{{ range $index, $label := $alerts.Labels.SortedPairs }}{{ if $index }},{{ end }}"{{ $label.Name }}":"{{ $label.Value }}"{{ end }}{{ "}" }},{{ end }}{{ if gt (len $alerts.Annotations.SortedPairs) 0 }}"annotations":{{ "{" }}{{ range $index, $annotations := $alerts.Annotations.SortedPairs }}{{ if $index }},{{ end }}"{{ $annotations.Name }}":"{{ $annotations.Value }}"{{ end }}{{ "}" }}{{ end }}}{{ end }}]}{{ end }}
    {{ define "sns.default.subject" }}[{{ .Status | toUpper }}{{ if eq .Status "firing" }}:{{ .Alerts.Firing | len }}{{ end }}]{{ end }}
alertmanager_config: |
  global:
  templates:
    - 'default_template'
  inhibit_rules:
  - source_match:
      severity: 'critical'
    target_match:
      severity: 'warning'
    equal: ['alertname']
  route:
    receiver: 'sns'
    group_by: ['...']
  receivers:
    - name: 'sns'
      sns_configs:
        - subject: 'prometheus_alert'
          sigv4:
            region: '${var.region}'
%{if var.alert_role_arn != null}
            role_arn: '${var.alert_role_arn}'
%{endif}
          topic_arn: '${var.alerts_sns_topics_arn}'        
          attributes:
            amp_arn: '${var.amp_name != null ? aws_prometheus_workspace.k8s.0.arn : var.amp_arn}'
            cluster_name: '${var.cluster_name}'
EOF
}

resource "aws_prometheus_rule_group_namespace" "k8s" {
  count = var.enable_alerts ? 1 : 0

  name         = "${var.cluster_name}-rules"
  workspace_id = var.amp_name != null ? aws_prometheus_workspace.k8s.0.id : var.amp_id
  data = var.amp_custom_alerting_rules == "" ? templatefile("${path.module}/rules.yaml", {
    amp_alerting_rules_exclude_namespace = var.amp_alerting_rules_exclude_namespace
  }) : var.amp_custom_alerting_rules
}
