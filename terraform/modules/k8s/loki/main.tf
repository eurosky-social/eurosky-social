resource "helm_release" "loki" {
  name      = "loki"
  namespace = "loki"

  create_namespace = true

  repository = "https://grafana.github.io/helm-charts"
  chart      = "loki"
  version    = "6.21.0"

  values = [
    templatefile("${path.module}/values.yaml", {
      storage_class        = var.storage_class
      s3_bucket            = var.s3_bucket
      s3_region            = var.s3_region
      s3_endpoint          = var.s3_endpoint
      s3_access_key        = var.s3_access_key
      s3_secret_key        = var.s3_secret_key
      monitoring_namespace = var.monitoring_namespace
    })
  ]

  timeout = 60 * 10
}

resource "helm_release" "alloy" {
  name      = "alloy"
  namespace = "monitoring"

  create_namespace = false

  repository = "https://grafana.github.io/helm-charts"
  chart      = "alloy"
  version    = "1.3.1"

  values = [
    templatefile("${path.module}/alloy-values.yaml", {
      loki_url = "http://loki.loki.svc.cluster.local:3100"
    })
  ]

  timeout = 60 * 15 # 15 minutes for DaemonSet rollout

  depends_on = [helm_release.loki]
}

# Additional NetworkPolicy to allow Loki pods (including sidecar) to access Kubernetes API server
# Required for k8s-sidecar to discover ConfigMaps with loki_rule label
resource "kubectl_manifest" "loki_egress_kube_apiserver" {
  yaml_body = templatefile("${path.module}/networkpolicy-apiserver.yaml", {
    namespace = "loki"
  })

  depends_on = [helm_release.loki]
}

# TODO: Switch to microservices mode for production HA (>100GB/day) - requires some strategy to not loose data or 10-15 mins logs downtime
# TODO: Add zone-aware ingester replication across AZs (zone_awareness_enabled + replication_factor: 3)
# TODO: Add PodDisruptionBudget for Loki single-binary pod to prevent data loss during cluster operations
