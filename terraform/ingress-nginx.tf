provider "kubernetes" {
  host                   = scaleway_k8s_cluster.kapsule_multi_az.kubeconfig[0].host
  token                  = scaleway_k8s_cluster.kapsule_multi_az.kubeconfig[0].token
  cluster_ca_certificate = base64decode(scaleway_k8s_cluster.kapsule_multi_az.kubeconfig[0].cluster_ca_certificate)
}

provider "kubectl" {
  host                   = scaleway_k8s_cluster.kapsule_multi_az.kubeconfig[0].host
  token                  = scaleway_k8s_cluster.kapsule_multi_az.kubeconfig[0].token
  cluster_ca_certificate = base64decode(scaleway_k8s_cluster.kapsule_multi_az.kubeconfig[0].cluster_ca_certificate)
  load_config_file       = false
}

provider "helm" {
  kubernetes {
    host                   = scaleway_k8s_cluster.kapsule_multi_az.kubeconfig[0].host
    token                  = scaleway_k8s_cluster.kapsule_multi_az.kubeconfig[0].token
    cluster_ca_certificate = base64decode(scaleway_k8s_cluster.kapsule_multi_az.kubeconfig[0].cluster_ca_certificate)
  }
}

resource "helm_release" "nginx_ingress" {
  name      = "ingress-nginx"
  namespace = "ingress-nginx"

  create_namespace = true

  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"

  depends_on = [
    scaleway_k8s_pool.pool-multi-az-v2
  ]

  values = [
    <<-EOT
        controller:
          replicaCount: 2 # prod 6?

          topologySpreadConstraints:
            - topologyKey: topology.kubernetes.io/zone
              maxSkew: 1
              whenUnsatisfiable: DoNotSchedule
              labelSelector:
                matchLabels:
                  app.kubernetes.io/name: ingress-nginx
                  app.kubernetes.io/instance: ingress-nginx
                  app.kubernetes.io/component: controller
          affinity:
            podAntiAffinity:
              requiredDuringSchedulingIgnoredDuringExecution:
              - labelSelector:
                  matchLabels:
                    app.kubernetes.io/name: ingress-nginx
                    app.kubernetes.io/instance: ingress-nginx
                    app.kubernetes.io/component: controller
                topologyKey: "kubernetes.io/hostname"
          service:
            enabled: false
        EOT
  ]
}

resource "kubernetes_service" "nginx" {
  for_each = toset(["fr-par-1", "fr-par-2"])

  metadata {
    name      = "ingress-nginx-controller-${each.key}"
    namespace = helm_release.nginx_ingress.namespace

    annotations = {
      "service.beta.kubernetes.io/scw-loadbalancer-zone" : each.key
      # external-dns will create DNS records automatically
      "external-dns.alpha.kubernetes.io/hostname" : "ingress.scw.eurosky.social"
      # Enable health checking
      "external-dns.alpha.kubernetes.io/healthcheck-mode" : "all"
      "external-dns.alpha.kubernetes.io/healthcheck-url" : "http://ingress.scw.eurosky.social/healthz"
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
      metadata[0].annotations["service.beta.kubernetes.io/scw-loadbalancer-id"],
      metadata[0].labels["k8s.scaleway.com/cluster"],
      metadata[0].labels["k8s.scaleway.com/kapsule"],
      metadata[0].labels["k8s.scaleway.com/managed-by-scaleway-cloud-controller-manager"],
    ]
  }
}