resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = "monitoring"
  }
}

resource "helm_release" "kube_prometheus_stack" {
  # Note: Manually update CRDs before upgrading chart (NOT auto-updated by helm)
  name      = "kube-prometheus-stack"
  namespace = kubernetes_namespace.monitoring.metadata[0].name

  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  version    = "78.5.0"

  values = [
    templatefile("${path.module}/values.yaml", {
      pds_dashboard_json               = jsonencode(jsondecode(file("${path.module}/dashboards/pds-dashboard.json")))
      relay_dashboard_json             = jsonencode(jsondecode(file("${path.module}/dashboards/relay-dashboard.json")))
      nginx_geoip_analytics_json       = jsonencode(jsondecode(file("${path.module}/dashboards/nginx-geoip-analytics.json")))
      grafana_admin_password           = var.grafana_admin_password
      storage_class                    = var.storage_class
      cluster_domain                   = var.cluster_domain
      alert_email                      = var.alert_email
      smtp_server                      = var.smtp_server
      smtp_port                        = var.smtp_port
      smtp_require_tls                 = var.smtp_require_tls
      smtp_username                    = var.smtp_username
      smtp_password                    = var.smtp_password
      deadmansswitch_url               = var.deadmansswitch_url
    })
  ]

  timeout = 60 * 15

  depends_on = [
    kubernetes_secret.thanos_objstore_config
  ]
}

resource "kubernetes_secret" "thanos_objstore_config" {
  metadata {
    name      = "thanos-objstore-config"
    namespace = kubernetes_namespace.monitoring.metadata[0].name
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
    namespace = helm_release.kube_prometheus_stack.namespace
  }

  data = {
    smtp_username = var.smtp_username
    smtp_password = var.smtp_password
  }

  type = "Opaque"
}

resource "kubectl_manifest" "deadmansswitch_rule" {
  count = var.deadmansswitch_url != "" ? 1 : 0

  yaml_body = templatefile("${path.module}/deadmansswitch-rule.yaml", {
    namespace = helm_release.kube_prometheus_stack.namespace
  })

  depends_on = [
    helm_release.kube_prometheus_stack
  ]
}

# TODO: Add recording rules for dashboard performance - defer until dashboard queries slow at scale
# TODO: Add NetworkPolicy for monitoring namespace - defer until multi-tenant or compliance required
