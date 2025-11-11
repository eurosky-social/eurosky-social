# CloudNativePG Alerting Rules
#
# Fetches official PrometheusRule from upstream CloudNativePG repository.

data "http" "cnpg_alerts" {
  url = "https://raw.githubusercontent.com/cloudnative-pg/cloudnative-pg/main/docs/src/samples/monitoring/prometheusrule.yaml"

  request_headers = {
    Accept = "application/yaml"
  }
}

locals {
  cnpg_alerts = yamldecode(data.http.cnpg_alerts.response_body)

  # Fix LastFailedArchiveTime alert to exclude replicas
  # See: https://github.com/cloudnative-pg/cloudnative-pg/issues/7086
  fixed_rules = [
    for rule in local.cnpg_alerts.spec.groups[0].rules :
    rule.alert == "LastFailedArchiveTime" ? merge(rule, {
      expr = "(1 - cnpg_pg_replication_in_recovery) * (cnpg_pg_stat_archiver_last_failed_time - cnpg_pg_stat_archiver_last_archived_time) > 1"
    }) : rule
  ]

  cnpg_alerts_fixed = merge(
    local.cnpg_alerts,
    {
      metadata = merge(
        local.cnpg_alerts.metadata,
        { namespace = "databases" }
      )
      spec = {
        groups = [
          merge(
            local.cnpg_alerts.spec.groups[0],
            { rules = local.fixed_rules }
          )
        ]
      }
    }
  )
}

resource "kubectl_manifest" "cnpg_alerts" {
  yaml_body = yamlencode(local.cnpg_alerts_fixed)

  depends_on = [kubernetes_namespace.databases]
}
