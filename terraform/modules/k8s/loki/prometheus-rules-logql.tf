# Loki Recording Rules (LogQL → Prometheus Metrics)

resource "kubernetes_config_map" "loki_record_rules" {
  metadata {
    name      = "loki-record-rules"
    namespace = "loki"
    labels = {
      "app.kubernetes.io/name"      = "loki"
      "app.kubernetes.io/component" = "alerting"
      "loki_rule"                   = "1"
    }
  }

  data = {
    "recording-rules.yaml" = file("${path.module}/loki-recording-rules.yaml")
  }

  depends_on = [helm_release.loki]
}

# Prometheus Alert Rules (PromQL) querying the pre-computed record rules

resource "kubectl_manifest" "prometheus_log_alerts" {
  yaml_body = file("${path.module}/prometheus-rules-logs.yaml")

  depends_on = [kubernetes_config_map.loki_record_rules]
}
