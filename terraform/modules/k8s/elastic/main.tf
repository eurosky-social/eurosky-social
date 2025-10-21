resource "helm_release" "eck_operator" {
  name             = "elastic-operator"
  namespace        = "elastic-system"
  create_namespace = true

  repository = "https://helm.elastic.co"
  chart      = "eck-operator"
  version    = "2.14.0"

  values = [
    templatefile("${path.module}/eck-operator-values.yaml", {
      resources_requests_cpu    = var.operator_resources_requests_cpu
      resources_requests_memory = var.operator_resources_requests_memory
      resources_limits_cpu      = var.operator_resources_limits_cpu
      resources_limits_memory   = var.operator_resources_limits_memory
    })
  ]
}

resource "kubectl_manifest" "elasticsearch" {
  yaml_body = templatefile("${path.module}/elasticsearch.yaml", {
    namespace                 = helm_release.eck_operator.namespace
    storage_class             = var.storage_class
    node_count                = var.es_node_count
    storage_size              = var.es_storage_size
    resources_requests_cpu    = var.es_resources_requests_cpu
    resources_requests_memory = var.es_resources_requests_memory
    resources_limits_cpu      = var.es_resources_limits_cpu
    resources_limits_memory   = var.es_resources_limits_memory
  })

  depends_on = [helm_release.eck_operator]
}

resource "kubectl_manifest" "kibana" {
  yaml_body = templatefile("${path.module}/kibana.yaml", {
    namespace                 = helm_release.eck_operator.namespace
    resources_requests_cpu    = var.kibana_resources_requests_cpu
    resources_requests_memory = var.kibana_resources_requests_memory
    resources_limits_cpu      = var.kibana_resources_limits_cpu
    resources_limits_memory   = var.kibana_resources_limits_memory
  })

  depends_on = [kubectl_manifest.elasticsearch]
}

resource "kubectl_manifest" "kibana_ingress" {
  yaml_body = templatefile("${path.module}/kibana-ingress.yaml", {
    namespace      = helm_release.eck_operator.namespace
    cluster_domain = var.cluster_domain
  })

  server_side_apply = true
  wait              = true

  depends_on = [kubectl_manifest.kibana]
}

# TODO: Increase resources for production workloads
# TODO: Configure snapshot/backup to object storage
# TODO: Add monitoring integration (Prometheus/Grafana)
# TODO: Configure autoscaling policies
# TODO: Increase node count and HA for production
