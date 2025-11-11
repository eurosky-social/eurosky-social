resource "kubernetes_deployment_v1" "pds" {
  count = var.enabled ? 1 : 0
  metadata {
    name = "pds-${var.partition}"
    labels = {
      app = "pds"
    }
  }

  spec {
    replicas = var.replicas
    selector {
      match_labels = {
        app = "pds"
      }
    }
    template {
      metadata {
        labels = {
          app = "pds"
        }
      }
      spec {
        container {
          name  = "pds"
          image = "${var.image_name}:${var.image_tag}"
          port {
            container_port = var.pds_port
          }
          env {
            name  = "NODE_ENV"
            value = "production"
          }
          env {
            name  = "PDS_ADMIN_PASSWORD"
            value = var.pds_admin_password
          }
          env {
            name  = "PDS_BLOBSTORE_DISK_LOCATION"
            value = var.pds_blobstore_disk_location
          }
          env {
            name  = "PDS_DATA_DIRECTORY"
            value = var.pds_data_directory
          }
          env {
            name  = "PDS_DID_PLC_URL"
            value = var.pds_did_plc_url
          }
          env {
            name  = "PDS_HOSTNAME"
            value = var.pds_hostname
          }
          env {
            name  = "PDS_JWT_SECRET"
            value = var.pds_jwt_secret
          }
          env {
            name  = "PDS_PORT"
            value = tostring(var.pds_port)
          }
          env {
            name  = "PDS_PLC_ROTATION_KEY_K256_PRIVATE_KEY_HEX"
            value = var.pds_plc_rotation_key_k256_private_key_hex
          }
          env {
            name  = "PDS_RECOVERY_DID_KEY"
            value = var.pds_recovery_did_key
          }
          env {
            name  = "PDS_DISABLE_SSRF_PROTECTION"
            value = tostring(var.pds_disable_ssrf_protection)
          }
          env {
            name  = "PDS_DEV_MODE"
            value = tostring(var.pds_dev_mode)
          }
          env {
            name  = "PDS_INVITE_REQUIRED"
            value = tostring(var.pds_invite_required)
          }
          env {
            name  = "PDS_BSKY_APP_VIEW_URL"
            value = var.pds_bsky_app_view_url
          }
          env {
            name  = "PDS_BSKY_APP_VIEW_DID"
            value = var.pds_bsky_app_view_did
          }
          env {
            name  = "PDS_EMAIL_SMTP_URL"
            value = var.pds_email_smtp_url
          }
          env {
            name  = "PDS_EMAIL_FROM_ADDRESS"
            value = var.pds_email_from_address
          }
          env {
            name  = "PDS_MODERATION_EMAIL_SMTP_URL"
            value = var.pds_moderation_email_smtp_url
          }
          env {
            name  = "PDS_MODERATION_EMAIL_ADDRESS"
            value = var.pds_moderation_email_address
          }
          env {
            name  = "PDS_MOD_SERVICE_URL"
            value = var.pds_mod_service_url
          }
          env {
            name  = "PDS_MOD_SERVICE_DID"
            value = var.pds_mod_service_did
          }
          env {
            name  = "LOG_ENABLED"
            value = tostring(var.log_enabled)
          }
          env {
            name  = "LOG_LEVEL"
            value = var.log_level
          }
          liveness_probe {
            http_get {
              path = "/xrpc/_health"
              port = var.pds_port
            }
            initial_delay_seconds = 10
            period_seconds        = 10
            timeout_seconds       = 3
            failure_threshold     = 3
          }
          readiness_probe {
            http_get {
              path = "/xrpc/_health"
              port = var.pds_port
            }
            initial_delay_seconds = 10
            period_seconds        = 10
            timeout_seconds       = 3
            failure_threshold     = 3
          }
        }
      }
    }
  }
}

resource "kubernetes_service_v1" "pds" {
  count = var.enabled ? 1 : 0
  metadata {
    name = "pds-${var.partition}"
    labels = {
      app = "pds"
    }
  }
  spec {
    selector = {
      app = "pds"
    }
    port {
      port        = var.pds_port
      target_port = var.pds_port
    }
    type = "ClusterIP"
  }
}

resource "kubernetes_ingress_v1" "pds" {
  count = var.enabled ? 1 : 0
  metadata {
    name = "pds-${var.partition}"
    labels = {
      app = "pds"
    }
    annotations = {
      "nginx.ingress.kubernetes.io/rewrite-target" = "/"
    }
  }

  spec {
    rule {
      host = "pds-${var.partition}.${var.domain}"
      http {
        path {
          path = "/"
          path_type = "Prefix"
          backend {
            service {
              name = "pds-${var.partition}"
              port {
                number = var.pds_port
              }
            }
          }
        }
      }
    }
  }
}
