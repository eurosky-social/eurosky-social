resource "helm_release" "nginx_ingress" {
  name      = "ingress-nginx"
  namespace = "ingress-nginx"

  create_namespace = true

  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  version    = "4.13.3"

  values = [
    templatefile("${path.module}/ingress-nginx-values.yaml", {
      replica_count        = var.replica_count
      topology_max_skew    = var.topology_max_skew
      release_name         = "ingress-nginx"
      maxmind_license_key  = var.maxmind_license_key
    })
  ]
}

resource "kubernetes_service" "nginx" {
  metadata {
    name      = "ingress-nginx-controller"
    namespace = helm_release.nginx_ingress.namespace

    annotations = merge(
      {
        "external-dns.alpha.kubernetes.io/hostname"         = "ingress.${var.cluster_domain}"
        "external-dns.alpha.kubernetes.io/healthcheck-mode" = "all"
        "external-dns.alpha.kubernetes.io/healthcheck-url"  = "http://ingress.${var.cluster_domain}/healthz"
      },
<<<<<<< HEAD
      var.extra_annotations
=======
      { for k, v in var.extra_nginx_annotations : k => replace(v, "ZONE_ALIAS_PLACEHOLDER", each.key) }
>>>>>>> d173284 (WIP)
    )
  }

  spec {
    selector = {
      "app.kubernetes.io/name"      = "ingress-nginx"
      "app.kubernetes.io/instance"  = "ingress-nginx"
      "app.kubernetes.io/component" = "controller"
    }

    port {
      app_protocol = "http"
      name         = "http"
      port         = 80
      protocol     = "TCP"
      target_port  = "http"
    }

    type                    = "LoadBalancer"
    external_traffic_policy = "Local"
  }
}

# TODO: Add custom error pages (controller.customErrorPages) for better UX
# TODO: Enable ModSecurity WAF (controller.config.enable-modsecurity, enable-owasp-modsecurity-crs) for production
# TODO: Configure HPA (Horizontal Pod Autoscaler) based on CPU/memory/requests for auto-scaling
# TODO: Add NetworkPolicy to restrict ingress controller traffic
# TODO: Configure upstream keepalive connections (controller.config.upstream-keepalive-*) for performance
# TODO: Add canary deployment support via ingress annotations for progressive rollouts
# TODO: Configure access logging (controller.config.access-log-path, error-log-path) for audit trail
# TODO: Configure max worker connections (controller.config.max-worker-connections) for high traffic
# TODO: Configure session affinity for WebSocket support (service.spec.sessionAffinity)
# TODO: Add health check intervals and timeouts for load balancers