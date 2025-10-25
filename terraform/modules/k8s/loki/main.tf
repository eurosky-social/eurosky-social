resource "helm_release" "loki" {
  name      = "loki"
  namespace = "monitoring"

  create_namespace = false # monitoring namespace already exists from prometheus-stack

  repository = "https://grafana.github.io/helm-charts"
  chart      = "loki"
  version    = "6.21.0"

  values = [
    templatefile("${path.module}/values.yaml", {
      storage_class      = var.storage_class
      s3_bucket          = var.s3_bucket
      s3_region          = var.s3_region
      s3_endpoint        = var.s3_endpoint
      s3_access_key      = var.s3_access_key
      s3_secret_key      = var.s3_secret_key
    })
  ]

  timeout = 60 * 10
}

resource "helm_release" "promtail" {
  name      = "promtail"
  namespace = "monitoring"

  create_namespace = false

  repository = "https://grafana.github.io/helm-charts"
  chart      = "promtail"
  version    = "6.16.6"

  values = [
    templatefile("${path.module}/promtail-values.yaml", {
      loki_url = "http://loki.monitoring.svc.cluster.local:3100"
    })
  ]

  depends_on = [helm_release.loki]
}

# TODO: Add Loki datasource to Grafana (via grafana.additionalDataSources in prometheus-stack values)
# TODO: Create Grafana dashboards for log exploration (gnetId: 13639 for Loki logs)
# TODO: Set up LogQL query examples for common troubleshooting scenarios
# TODO: Configure PrometheusRules with LogQL alert rules for critical log patterns (errors, panics, OOM, crash loops)
# TODO: Add retention policies cleanup job for old S3 data (S3 lifecycle policy at bucket level)
# TODO: Consider switching to microservices mode for production HA (official recommendation per Grafana docs)
# TODO: Add zone-aware ingester replication across AZs (zone_awareness_enabled + replication_factor: 3)
# TODO: Configure Loki ingester WAL for better durability and faster recovery after crashes
# TODO: Add PodDisruptionBudget for Loki single-binary pod to prevent data loss during cluster operations
# TODO: Implement backup/restore procedures for Loki index (currently stored in PVC - vulnerable to PV failures)
# TODO: Add NetworkPolicy to restrict Loki access to authorized pods only (Promtail, Grafana)
