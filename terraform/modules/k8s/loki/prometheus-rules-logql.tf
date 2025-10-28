# Loki Log-Based Alerting Rules (LogQL)
#
# NOTE: Deployed as ConfigMap for Loki's ruler to discover via Kubernetes API
# (NOT as PrometheusRule - which only supports PromQL, not LogQL)
#
# How it works:
# 1. Loki's ruler (enabled with kubernetes.enabled: true) discovers this ConfigMap
# 2. Rules are evaluated every 5 minutes using LogQL syntax
# 3. Matching alerts fire to Prometheus Alertmanager
# Reference: https://grafana.com/docs/loki/latest/alert/

resource "kubernetes_config_map" "loki_alert_rules" {
  metadata {
    name      = "loki-alert-rules"
    namespace = "monitoring"
    labels = {
      "app.kubernetes.io/name"      = "loki"
      "app.kubernetes.io/component" = "alerting"
      "loki_rule"                   = "1"
    }
  }

  data = {
    "alert-rules.yaml" = <<-YAML
      name: loki-log-alerts
      interval: 5m
      rules:
        - alert: ApplicationErrorLogsDetected
          expr: count(count_over_time({namespace!="kube-system",namespace!="kube-public"} |= "ERROR" [5m])) > 10
          for: 5m
          annotations:
            summary: "Application error logs detected"
            description: "Application logs contain errors in the last 5 minutes"
          labels:
            severity: warning
            component: application

        - alert: ApplicationPanicDetected
          expr: count(count_over_time({namespace!="kube-system",namespace!="kube-public"} |= "panic" [5m])) > 0
          for: 1m
          annotations:
            summary: "Application panic or fatal error detected"
            description: "Critical errors detected in application logs"
          labels:
            severity: critical
            component: application

        - alert: OutOfMemoryErrorDetected
          expr: count(count_over_time({namespace!="kube-system",namespace!="kube-public"} |= "OOM" [5m])) > 0
          for: 1m
          annotations:
            summary: "Out of memory error detected"
            description: "OOM kill or memory exhaustion detected in application logs"
          labels:
            severity: critical
            component: application

        - alert: DatabaseConnectivityError
          expr: count(count_over_time({namespace!="kube-system",namespace!="kube-public"} |= "database" |= "connection" |= "refused" [5m])) > 5
          for: 3m
          annotations:
            summary: "Database connectivity errors detected"
            description: "Database connection errors in application logs"
          labels:
            severity: warning
            component: database

        - alert: HighTimeoutRate
          expr: count(count_over_time({namespace!="kube-system",namespace!="kube-public"} |= "timeout" or |= "deadline exceeded" [5m])) > 20
          for: 5m
          annotations:
            summary: "High timeout rate in application logs"
            description: "Timeout events detected in application logs"
          labels:
            severity: warning
            component: application
    YAML
  }

  depends_on = [helm_release.loki]
}
