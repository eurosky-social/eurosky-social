# TODO: Increase resources for production workloads
# TODO: Configure snapshot/backup to object storage
# TODO: Add monitoring integration (Prometheus/Grafana)
# TODO: Configure autoscaling policies
# TODO: Increase node count and HA for production

resource "helm_release" "eck_operator" {
  name             = "elastic-operator"
  namespace        = "elastic-system"
  create_namespace = true

  repository = "https://helm.elastic.co"
  chart      = "eck-operator"
  version    = "2.14.0"

  values = [
    templatefile("${path.module}/eck-operator-values.yaml", {
      resources_requests_cpu    = "50m"
      resources_requests_memory = "100Mi"
      resources_limits_cpu      = "500m"
      resources_limits_memory   = "256Mi"
    })
  ]
}

resource "kubectl_manifest" "elasticsearch" {
  yaml_body = templatefile("${path.module}/elasticsearch.yaml", {
    namespace                 = helm_release.eck_operator.namespace
    storage_class             = var.elasticsearch_storage_class
    node_count                = 1
    storage_size              = "2Gi"
    resources_requests_cpu    = "100m"
    resources_requests_memory = "1Gi"
    resources_limits_cpu      = "500m"
    resources_limits_memory   = "1Gi"
  })
}

resource "kubectl_manifest" "kibana" {
  yaml_body = templatefile("${path.module}/kibana.yaml", {
    namespace                 = helm_release.eck_operator.namespace
    resources_requests_cpu    = "100m"
    resources_requests_memory = "512Mi"
    resources_limits_cpu      = "1000m"
    resources_limits_memory   = "1Gi"
  })
}

resource "kubectl_manifest" "kibana_ingress" {
  yaml_body = templatefile("${path.module}/kibana-ingress.yaml", {
    namespace      = helm_release.eck_operator.namespace
    cluster_domain = var.cluster_domain
  })

  server_side_apply = true
  wait              = true
}
