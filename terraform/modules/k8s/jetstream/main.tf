locals {
  namespace      = "jetstream"
  jetstream_image = "ghcr.io/eurosky-social/jetstream:latest"
}

resource "kubernetes_namespace" "jetstream" {
  metadata {
    name = local.namespace
  }
}

resource "kubernetes_config_map" "jetstream_config" {
  metadata {
    name      = "jetstream-config"
    namespace = kubernetes_namespace.jetstream.metadata[0].name
  }

  data = {
    JETSTREAM_WS_URL                = "wss://relay.${var.cluster_domain}/xrpc/com.atproto.sync.subscribeRepos"
    JETSTREAM_DATA_DIR              = "/data"
    JETSTREAM_LISTEN_ADDR           = ":6008"
    JETSTREAM_METRICS_LISTEN_ADDR   = ":6009"
    JETSTREAM_WORKER_COUNT          = "100"
    JETSTREAM_LIVENESS_TTL          = "30s"
    LOG_LEVEL                       = "info"
  }
}

resource "kubernetes_stateful_set" "jetstream" {
  metadata {
    name      = "jetstream"
    namespace = kubernetes_namespace.jetstream.metadata[0].name
    labels = {
      app = "jetstream"
    }
  }

  spec {
    replicas = 1

    service_name = "jetstream"

    selector {
      match_labels = {
        app = "jetstream"
      }
    }

    volume_claim_template {
      metadata {
        name = "jetstream-data"
      }

      spec {
        access_modes = ["ReadWriteOnce"]

        resources {
          requests = {
            storage = "20Gi"
          }
        }
      }
    }

    template {
      metadata {
        labels = {
          app = "jetstream"
        }
      }

      spec {
        container {
          name  = "jetstream"
          image = local.jetstream_image

          port {
            name           = "api"
            container_port = 6008
            protocol       = "TCP"
          }

          port {
            name           = "metrics"
            container_port = 6009
            protocol       = "TCP"
          }

          env_from {
            config_map_ref {
              name = kubernetes_config_map.jetstream_config.metadata[0].name
            }
          }

          volume_mount {
            name       = "jetstream-data"
            mount_path = "/data"
          }

          resources {
            requests = {
              memory = "256Mi"
              cpu    = "200m"
            }
            limits = {
              memory = "1Gi"
              cpu    = "1000m"
            }
          }

          liveness_probe {
            http_get {
              path = "/"
              port = 6008
            }
            initial_delay_seconds = 10
            period_seconds        = 10
            timeout_seconds       = 5
            failure_threshold     = 3
          }

          readiness_probe {
            http_get {
              path = "/"
              port = 6008
            }
            initial_delay_seconds = 5
            period_seconds        = 5
            timeout_seconds       = 3
            failure_threshold     = 3
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "jetstream" {
  metadata {
    name      = "jetstream"
    namespace = kubernetes_namespace.jetstream.metadata[0].name
    labels = {
      app = "jetstream"
    }
  }

  spec {
    selector = {
      app = "jetstream"
    }

    port {
      name        = "api"
      port        = 6008
      target_port = 6008
      protocol    = "TCP"
    }

    port {
      name        = "metrics"
      port        = 6009
      target_port = 6009
      protocol    = "TCP"
    }

    type = "ClusterIP"
  }
}

resource "kubectl_manifest" "jetstream_ingress" {
  yaml_body = templatefile("${path.module}/jetstream-ingress.yaml", {
    namespace      = kubernetes_namespace.jetstream.metadata[0].name
    hostname       = "jetstream.${var.cluster_domain}"
    cluster_domain = var.cluster_domain
  })

  server_side_apply = true
  wait              = true
}
