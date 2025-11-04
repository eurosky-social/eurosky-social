# Extended RBAC for Prometheus to discover PodMonitors
#
# The kube-prometheus-stack Helm chart's default ClusterRole does not include
# permissions for 'podmonitors', which prevents Prometheus from discovering
# PodMonitors created by component-owned modules (postgres, loki, etc).

resource "kubernetes_cluster_role" "prometheus_podmonitor_reader" {
  metadata {
    name = "prometheus-podmonitor-reader"
  }

  rule {
    api_groups = ["monitoring.coreos.com"]
    resources  = ["podmonitors"]
    verbs      = ["list", "watch", "get"]
  }
}

resource "kubernetes_cluster_role_binding" "prometheus_podmonitor_reader" {
  metadata {
    name = "prometheus-podmonitor-reader"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.prometheus_podmonitor_reader.metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = "kube-prometheus-stack-prometheus"
    namespace = helm_release.kube_prometheus_stack.namespace
  }

  depends_on = [helm_release.kube_prometheus_stack]
}
