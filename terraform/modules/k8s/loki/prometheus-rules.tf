# Source: Official Loki monitoring mixin from Grafana's Loki repository
# https://grafana.com/docs/loki/latest/operations/meta-monitoring/
data "http" "loki_rules" {
  url = "https://raw.githubusercontent.com/grafana/loki/main/production/loki-mixin-compiled/rules.yaml"

  request_headers = {
    Accept = "application/yaml"
  }
}

# Fetch alert rules from official Grafana Loki repository
data "http" "loki_alerts" {
  url = "https://raw.githubusercontent.com/grafana/loki/main/production/loki-mixin-compiled/alerts.yaml"

  request_headers = {
    Accept = "application/yaml"
  }
}

# Recording rules (pre-computed metrics for alerts)
resource "kubectl_manifest" "loki_rules" {
  yaml_body = <<-YAML
    apiVersion: monitoring.coreos.com/v1
    kind: PrometheusRule
    metadata:
      name: loki-recording-rules
      namespace: monitoring
      labels:
        app.kubernetes.io/name: prometheus
        app.kubernetes.io/component: recording
    spec:
      ${indent(6, data.http.loki_rules.response_body)}
  YAML

  depends_on = [helm_release.loki]
}

# Alert rules
resource "kubectl_manifest" "loki_alerts" {
  yaml_body = <<-YAML
    apiVersion: monitoring.coreos.com/v1
    kind: PrometheusRule
    metadata:
      name: loki-alerts
      namespace: monitoring
      labels:
        app.kubernetes.io/name: prometheus
        app.kubernetes.io/component: alerting
    spec:
      ${indent(6, data.http.loki_alerts.response_body)}
  YAML

  depends_on = [helm_release.loki]
}
