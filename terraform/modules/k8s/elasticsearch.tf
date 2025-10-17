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

resource "kubernetes_ingress_v1" "kibana" {
  metadata {
    name      = "kibana"
    namespace = helm_release.eck_operator.namespace

    annotations = {
      "cert-manager.io/cluster-issuer"               = "letsencrypt-prod"
      "nginx.ingress.kubernetes.io/backend-protocol" = "HTTPS"
      "external-dns.alpha.kubernetes.io/target"      = "ingress.${var.cluster_domain}"
    }
  }

  spec {
    ingress_class_name = "nginx"

    tls {
      hosts       = ["kibana.${var.cluster_domain}"]
      secret_name = "kibana-tls"
    }

    rule {
      host = "kibana.${var.cluster_domain}"
      http {
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = "kibana-kb-http"
              port {
                number = 5601
              }
            }
          }
        }
      }
    }
  }
}
