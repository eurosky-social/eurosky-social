# TODO: Configure rate limiting (controller.config.limit-req-status-code, limit-conn-status-code)
# TODO: Consider parameterizing replica_count via variable for different environments
resource "helm_release" "nginx_ingress" {
  name      = "ingress-nginx"
  namespace = "ingress-nginx"

  create_namespace = true

  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  version    = "4.13.3"

  values = [
    templatefile("${path.module}/ingress-nginx-values.yaml", {
      replica_count     = 2
      topology_max_skew = 1
      release_name      = "ingress-nginx"
    })
  ]
}

resource "kubernetes_service" "nginx" {
  for_each = toset(var.ingress_nginx_zones)

  metadata {
    name      = "ingress-nginx-controller-${each.key}"
    namespace = helm_release.nginx_ingress.namespace

    annotations = {
      # TODO cloud provider specific configuration, should be extracted
      "service.beta.kubernetes.io/scw-loadbalancer-zone"  = each.key
      "external-dns.alpha.kubernetes.io/hostname"         = "ingress.${var.cluster_domain}"
      "external-dns.alpha.kubernetes.io/healthcheck-mode" = "all"
      "external-dns.alpha.kubernetes.io/healthcheck-url"  = "http://ingress.${var.cluster_domain}/healthz"
    }
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
      # TODO cloud provider specific configuration, should be extracted
      metadata[0].annotations["service.beta.kubernetes.io/scw-loadbalancer-id"],
      metadata[0].labels["k8s.scaleway.com/cluster"],
      metadata[0].labels["k8s.scaleway.com/kapsule"],
      metadata[0].labels["k8s.scaleway.com/managed-by-scaleway-cloud-controller-manager"],
    ]
  }
}
