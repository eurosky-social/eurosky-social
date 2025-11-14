locals {
  namespace  = "hepa"
  hepa_image = "ghcr.io/eurosky-social/indigo:hepa-eurosky-latest"
}

resource "kubernetes_namespace" "hepa" {
  metadata {
    name = local.namespace
  }
}

resource "kubernetes_config_map" "hepa_config" {
  metadata {
    name      = "hepa-config"
    namespace = kubernetes_namespace.hepa.metadata[0].name
  }

  data = {
    ATP_BSKY_HOST          = "https://api.bsky.app"
    ATP_OZONE_HOST         = "https://live2025demo-ozone.${var.cluster_domain}"
    ATP_PDS_HOST           = "https://live2025demo.${var.cluster_domain}"
    ATP_PLC_HOST           = "https://plc.directory"
    ATP_RELAY_HOST         = "wss://relay.${var.cluster_domain}"
    HEPA_COLLECTION_FILTER = "app.flashes.story"
    HEPA_LOG_LEVEL         = "info"
    HEPA_METRICS_LISTEN    = ":3989"
    HEPA_OZONE_DID         = var.ozone_did
    HEPA_RULESET           = "default"
    LOG_LEVEL              = "info"
    NODE_ENV               = "production"
  }
}

resource "kubectl_manifest" "hepa_secrets" {
  yaml_body = yamlencode({
    apiVersion = "v1"
    kind       = "Secret"
    metadata = {
      name      = "hepa-secrets"
      namespace = kubernetes_namespace.hepa.metadata[0].name
    }
    type = "Opaque"
    stringData = {
      HEPA_OZONE_AUTH_ADMIN_TOKEN = var.ozone_admin_password
      HEPA_PDS_AUTH_ADMIN_TOKEN   = var.pds_admin_password
    }
  })

  server_side_apply = true
  wait              = true
}

resource "kubernetes_deployment" "hepa" {
  metadata {
    name      = "hepa"
    namespace = kubernetes_namespace.hepa.metadata[0].name
    labels = {
      app = "hepa"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "hepa"
      }
    }

    template {
      metadata {
        labels = {
          app = "hepa"
        }
      }

      spec {
        container {
          name  = "hepa"
          image = local.hepa_image

          port {
            name           = "metrics"
            container_port = 3989
            protocol       = "TCP"
          }

          env_from {
            config_map_ref {
              name = kubernetes_config_map.hepa_config.metadata[0].name
            }
          }

          env_from {
            secret_ref {
              name = "hepa-secrets"
            }
          }

          resources {
            requests = {
              memory = "128Mi"
              cpu    = "50m"
            }
            limits = {
              memory = "512Mi"
              cpu    = "500m"
            }
          }

          liveness_probe {
            http_get {
              path = "/metrics"
              port = 3989
            }
            initial_delay_seconds = 30
            period_seconds        = 10
            timeout_seconds       = 5
            failure_threshold     = 3
          }

          readiness_probe {
            http_get {
              path = "/metrics"
              port = 3989
            }
            initial_delay_seconds = 10
            period_seconds        = 5
            timeout_seconds       = 3
            failure_threshold     = 3
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "hepa_metrics" {
  metadata {
    name      = "hepa-metrics"
    namespace = kubernetes_namespace.hepa.metadata[0].name
    labels = {
      app = "hepa"
    }
  }

  spec {
    selector = {
      app = "hepa"
    }

    port {
      name        = "metrics"
      port        = 3989
      target_port = 3989
      protocol    = "TCP"
    }

    type = "ClusterIP"
  }
}
