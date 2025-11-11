resource "helm_release" "kube_prometheus_stack" {
  name      = "kube-prometheus-stack"
  namespace = "monitoring"

  create_namespace = true

  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  version    = "78.5.0"

  values = [
    templatefile("${path.module}/values.yaml", {
      grafana_admin_password = var.grafana_admin_password
      storage_class          = var.storage_class
    })
  ]

  timeout = 60 * 10
}

# TODO: Manually update CRDs before upgrading chart (NOT auto-updated by helm)
# TODO: Add PodDisruptionBudget for HA components (minAvailable=1)
# TODO: Add priorityClassName for critical monitoring workloads
# TODO: Configure remote_write for long-term storage (Thanos/Mimir/object storage)
# TODO: Create ServiceMonitors for app workloads (use CRDs, NOT prometheus.io/scrape annotations)
# TODO: Add PrometheusRules for infrastructure alerts (node/pod health, resource exhaustion)
# TODO: Configure recording rules to reduce dashboard query load
# TODO: Add NetworkPolicy to restrict monitoring namespace traffic
