# CloudNativePG Alerting Rules
#
# Fetches official PrometheusRule from upstream CloudNativePG repository.

data "http" "cnpg_alerts" {
  url = "https://raw.githubusercontent.com/cloudnative-pg/cloudnative-pg/main/docs/src/samples/monitoring/prometheusrule.yaml"

  request_headers = {
    Accept = "application/yaml"
  }
}

resource "kubectl_manifest" "cnpg_alerts" {
  yaml_body = yamldecode(data.http.cnpg_alerts.response_body) != null ? (
    yamlencode(merge(
      yamldecode(data.http.cnpg_alerts.response_body),
      {
        metadata = merge(
          yamldecode(data.http.cnpg_alerts.response_body).metadata,
          { namespace = "databases" }
        )
      }
    ))
  ) : data.http.cnpg_alerts.response_body

  depends_on = [kubernetes_namespace.databases]
}
