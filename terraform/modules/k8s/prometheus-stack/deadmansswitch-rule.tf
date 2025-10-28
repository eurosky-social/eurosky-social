# Dead Man's Switch Alert Rule

resource "kubectl_manifest" "deadmansswitch_rule" {
  count = var.deadmansswitch_url != "" ? 1 : 0

  yaml_body = <<-YAML
    apiVersion: monitoring.coreos.com/v1
    kind: PrometheusRule
    metadata:
      name: deadmansswitch
      namespace: monitoring
      labels:
        app.kubernetes.io/name: prometheus
        app.kubernetes.io/component: alerting
    spec:
      groups:
        - name: meta
          interval: 300s
          rules:
            - alert: DeadMansSwitch
              expr: vector(1)
              labels:
                severity: none
              annotations:
                summary: "Prometheus heartbeat"
                description: "This alert continuously fires to indicate Prometheus and Alertmanager are operational. External monitoring should expect this alert every minute."
  YAML

  depends_on = [helm_release.kube_prometheus_stack]
}
