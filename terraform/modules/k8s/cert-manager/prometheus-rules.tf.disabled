# cert-manager Alerting Rules
#
# Fetches official PrometheusRule from upstream monitoring-mixins repository.
# Rules are deployed to the "cert-manager" namespace (component-owned pattern).
#
# Why component-owned namespace?
# - Follows Kubernetes principle: each component owns its observability in its namespace
# - Prometheus discovers rules cluster-wide via empty ruleNamespaceSelector
# - Easier to manage component lifecycle (no cross-namespace dependencies)
# - Aligns with Loki/K8s-native pattern where components own their alerts
#
data "http" "cert_manager_alerts" {
  url = "https://raw.githubusercontent.com/monitoring-mixins/website/master/assets/cert-manager/alerts.yaml"

  request_headers = {
    Accept = "application/yaml"
  }
}

resource "kubectl_manifest" "cert_manager_alerts" {
  yaml_body = <<-YAML
    apiVersion: monitoring.coreos.com/v1
    kind: PrometheusRule
    metadata:
      name: cert-manager-alerts
      namespace: cert-manager
      labels:
        app.kubernetes.io/name: prometheus
        app.kubernetes.io/component: alerting
    spec:
      ${indent(6, data.http.cert_manager_alerts.response_body)}
  YAML

  depends_on = [helm_release.cert_manager]
}
