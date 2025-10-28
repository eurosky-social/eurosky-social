resource "helm_release" "kube_prometheus_stack" {
# Note: Manually update CRDs before upgrading chart (NOT auto-updated by helm)
  name             = "kube-prometheus-stack"
  namespace        = "monitoring"
  create_namespace = true

  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  version    = "78.5.0"

  values = [
    templatefile("${path.module}/values.yaml", {
      grafana_admin_password = var.grafana_admin_password
      storage_class          = var.storage_class
      cluster_domain         = var.cluster_domain
      alert_email            = var.alert_email
      smtp_server            = var.smtp_server
      smtp_port              = var.smtp_port
      smtp_require_tls       = var.smtp_require_tls
      smtp_username          = var.smtp_username
      smtp_password          = var.smtp_password
    })
  ]

  timeout = 60 * 15

  depends_on = [
    kubernetes_priority_class.system_cluster_critical,
    kubernetes_secret.thanos_objstore_config
  ]
}

resource "kubernetes_secret" "thanos_objstore_config" {
  metadata {
    name      = "thanos-objstore-config"
    namespace = "monitoring"
  }

  data = {
    "thanos.yaml" = <<-EOY
type: s3
config:
  bucket: ${var.thanos_s3_bucket}
  endpoint: ${replace(replace(var.thanos_s3_endpoint, "https://", ""), "http://", "")}
  region: ${var.thanos_s3_region}
  access_key: ${var.thanos_s3_access_key}
  secret_key: ${var.thanos_s3_secret_key}
EOY
  }

  type = "Opaque"
}

resource "kubernetes_secret" "alertmanager_smtp" {
  metadata {
    name      = "alertmanager-smtp-config"
    namespace = "monitoring"
  }

  data = {
    smtp_username = var.smtp_username
    smtp_password = var.smtp_password
  }

  type = "Opaque"
}

resource "kubernetes_priority_class" "system_cluster_critical" {
  metadata {
    name = "system-cluster-critical"
  }

  value       = 2000000000
  description = "Critical cluster components - monitoring, DNS, etc. Prevents eviction during node pressure."
}

# TODO: Add PodDisruptionBudget for HA components (minAvailable=1) - needed for go live
# TODO: Add recording rules for dashboard performance - defer until dashboard queries slow at scale
# TODO: Add NetworkPolicy for monitoring namespace - defer until multi-tenant or compliance required
