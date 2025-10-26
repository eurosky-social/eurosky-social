# nginx-ingress Alerting Rules
# Custom rules aligned with official Helm chart examples
# Source: https://github.com/kubernetes/ingress-nginx/blob/main/charts/ingress-nginx/values.yaml

resource "kubectl_manifest" "ingress_nginx_alerts" {
  yaml_body = <<-YAML
    apiVersion: monitoring.coreos.com/v1
    kind: PrometheusRule
    metadata:
      name: ingress-nginx-alerts
      namespace: ingress-nginx
      labels:
        app.kubernetes.io/name: prometheus
        app.kubernetes.io/component: alerting
    spec:
      groups:
        - name: ingress-nginx-alerts
          interval: 1m
          rules:
            - alert: NginxHigh4xxRate
              annotations:
                summary: "Nginx ingress high 4xx error rate"
                description: 'Nginx ingress is experiencing {{ printf "%.2f" $value }}% 4xx errors.'
                runbook_url: https://kubernetes.github.io/ingress-nginx/troubleshooting/
              expr: |
                100 * sum(rate(nginx_ingress_controller_requests{status=~"4.."}[5m]))
                  /
                sum(rate(nginx_ingress_controller_requests[5m]))
                  > 10
              for: 5m
              labels:
                severity: warning
                component: ingress

            - alert: NginxHigh5xxRate
              annotations:
                summary: "Nginx ingress high 5xx error rate"
                description: 'Nginx ingress is experiencing {{ printf "%.2f" $value }}% 5xx errors.'
                runbook_url: https://kubernetes.github.io/ingress-nginx/troubleshooting/
              expr: |
                100 * sum(rate(nginx_ingress_controller_requests{status=~"5.."}[5m]))
                  /
                sum(rate(nginx_ingress_controller_requests[5m]))
                  > 5
              for: 5m
              labels:
                severity: critical
                component: ingress

            - alert: NginxHighLatency
              annotations:
                summary: "Nginx ingress high latency"
                description: "Nginx ingress p99 latency is {{ $value }}s for ingress {{ $labels.ingress }}."
                runbook_url: https://kubernetes.github.io/ingress-nginx/troubleshooting/
              expr: |
                histogram_quantile(0.99,
                  sum by (le, ingress) (
                    rate(nginx_ingress_controller_request_duration_seconds_bucket[5m])
                  )
                ) > 5
              for: 10m
              labels:
                severity: warning
                component: ingress

            - alert: NginxConfigReloadFailed
              annotations:
                summary: "Nginx config reload failed"
                description: "Nginx ingress controller failed to reload configuration."
                runbook_url: https://kubernetes.github.io/ingress-nginx/troubleshooting/
              expr: |
                nginx_ingress_controller_config_last_reload_successful == 0
              for: 5m
              labels:
                severity: critical
                component: ingress
  YAML

  depends_on = [helm_release.nginx_ingress]
}
