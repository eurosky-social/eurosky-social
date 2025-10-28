resource "helm_release" "nginx_ingress" {
  name      = "ingress-nginx"
  namespace = "ingress-nginx"

  create_namespace = true

  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  version    = "4.13.3"

  values = [
    templatefile("${path.module}/ingress-nginx-values.yaml", {
      replica_count     = var.replica_count
      topology_max_skew = var.topology_max_skew
      release_name      = "ingress-nginx"
    })
  ]
}

resource "kubernetes_service" "nginx" {
  for_each = toset(var.zones)

  metadata {
    name      = "ingress-nginx-controller-${each.key}"
    namespace = helm_release.nginx_ingress.namespace

    annotations = merge(
      {
        "external-dns.alpha.kubernetes.io/hostname"         = "ingress.${var.cluster_domain}"
        "external-dns.alpha.kubernetes.io/healthcheck-mode" = "all"
        "external-dns.alpha.kubernetes.io/healthcheck-url"  = "http://ingress.${var.cluster_domain}/healthz"
      },
      var.cloud_provider == "scaleway" ? {
        "service.beta.kubernetes.io/scw-loadbalancer-zone"           = each.key
        "service.beta.kubernetes.io/scw-loadbalancer-timeout-tunnel" = "120000"
      } : {}
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

    port {
      app_protocol = "https"
      name         = "https"
      port         = 443
      protocol     = "TCP"
      target_port  = "https"
    }

    type = "LoadBalancer"
  }

  lifecycle {
    ignore_changes = [
      metadata[0].annotations["service.beta.kubernetes.io/scw-loadbalancer-id"],
      metadata[0].labels["k8s.scaleway.com/cluster"],
      metadata[0].labels["k8s.scaleway.com/kapsule"],
      metadata[0].labels["k8s.scaleway.com/managed-by-scaleway-cloud-controller-manager"],
    ]
  }
}

# TODO: Configure rate limiting (controller.config.limit-req-status-code, limit-conn-status-code)
# TODO: Consider parameterizing replica_count via variable for different environments
# TODO: Add PodMonitor for enhanced observability of controller pods
# TODO: Configure connection draining timeout (controller.lifecycle.preStop.exec.command for zero-downtime)
# TODO: Add custom error pages (controller.customErrorPages) for better UX
# TODO: Configure SSL protocols and ciphers (controller.config.ssl-protocols, ssl-ciphers) for security
# TODO: Enable ModSecurity WAF (controller.config.enable-modsecurity, enable-owasp-modsecurity-crs) for production
# TODO: Configure log format for structured logging (controller.config.log-format-upstream)
# TODO: Add priorityClassName=system-cluster-critical for ingress controller pods
# TODO: Configure HPA (Horizontal Pod Autoscaler) based on CPU/memory/requests for auto-scaling
# TODO: Add NetworkPolicy to restrict ingress controller traffic
# TODO: Configure client body size limits (controller.config.proxy-body-size) to prevent abuse
# TODO: Add custom headers for security (X-Frame-Options, X-Content-Type-Options, etc.)
# TODO: Configure upstream keepalive connections (controller.config.upstream-keepalive-*) for performance
# TODO: Add canary deployment support via ingress annotations for progressive rollouts
# TODO: Configure access logging (controller.config.access-log-path, error-log-path) for audit trail
# TODO: Add admission webhook validation for Ingress resources
# TODO: Configure max worker connections (controller.config.max-worker-connections) for high traffic
# TODO: Add external traffic policy (service.spec.externalTrafficPolicy=Local) to preserve client IP
# TODO: Configure session affinity for WebSocket support (service.spec.sessionAffinity)
# TODO: Add health check intervals and timeouts for load balancers
# TODO: Configure TLS termination settings (ssl-session-cache, ssl-session-timeout)
# TODO: Add DDoS protection via rate limiting per IP (controller.config.limit-req-zone)
# TODO: Consider moving to values file approach for better maintainability
