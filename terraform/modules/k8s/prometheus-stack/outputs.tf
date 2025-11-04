output "monitoring_namespace" {
  description = "Kubernetes namespace where Prometheus stack is deployed"
  value       = helm_release.kube_prometheus_stack.namespace
}
