# external-dns Alerting Rules
# Custom rules for DNS provider connectivity monitoring

resource "kubectl_manifest" "external_dns_alerts" {
  yaml_body = <<-YAML
    apiVersion: monitoring.coreos.com/v1
    kind: PrometheusRule
    metadata:
      name: external-dns-alerts
      namespace: kube-system
      labels:
        app.kubernetes.io/name: prometheus
        app.kubernetes.io/component: alerting
    spec:
      groups:
        - name: external-dns-alerts
          interval: 1m
          rules:
            - alert: ExternalDNSRegistryErrors
              annotations:
                summary: "external-dns is experiencing registry errors"
                description: "external-dns has {{ $value }} registry errors in the last 5 minutes. Check DNS provider credentials and connectivity."
                runbook_url: https://github.com/kubernetes-sigs/external-dns/blob/master/docs/faq.md
              expr: |
                rate(external_dns_registry_errors_total[5m]) > 0.1
              for: 5m
              labels:
                severity: warning
                component: dns

            - alert: ExternalDNSSourceErrors
              annotations:
                summary: "external-dns is experiencing source errors"
                description: "external-dns has {{ $value }} source errors in the last 5 minutes. Check Kubernetes API connectivity and RBAC permissions."
                runbook_url: https://github.com/kubernetes-sigs/external-dns/blob/master/docs/faq.md
              expr: |
                rate(external_dns_source_errors_total[5m]) > 0.1
              for: 5m
              labels:
                severity: warning
                component: dns
  YAML

  depends_on = [helm_release.external_dns]
}
