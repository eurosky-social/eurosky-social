resource "kubernetes_deployment_v1" "plc" {

  metadata {
    name = "plc-${var.partition}"
    labels = {
      app = "plc"
    }
  }

  spec {
    replicas = var.replicas
    selector {
      match_labels = {
        app = "plc"
      }
    }
    template {
      metadata {
        labels = {
          app = "plc"
        }
      }
      spec {
        container {
          name  = "plc"
          image = "${var.image_name}:${var.image_tag}"
          port {
            container_port = 3000
          }
          env {
            name  = "PORT"
            value = "3000"
          }
          env {
            name  = "DB_CREDS_JSON"
            value = jsonencode({
              username = "plc_user",
              password = var.plc_db_password,
              host     = "${var.postgres_cluster_name}-rw.${var.postgres_namespace}.svc.cluster.local",
              database = "plc_dev"
            })
          }
          env {
            name  = "DEBUG_MODE"
            value = "1"
          }
          env {
            name  = "LOG_ENABLED"
            value = "true"
          }
          env {
            name  = "LOG_LEVEL"
            value = "debug"
          }
          env {
            name  = "LOG_DESTINATION"
            value = "1"
          }
        }
      }
    }
  }
}

resource "kubernetes_service_v1" "plc" {

  metadata {
    name = "plc-${var.partition}"
    labels = {
      app = "plc"
    }
  }
  spec {
    selector = {
      app = "plc"
    }
    port {
      port        = 3000
      target_port = 3000
    }
    type = "ClusterIP"
  }
}

resource "kubernetes_ingress_v1" "plc" {

  metadata {
    name = "plc-${var.partition}"
    labels = {
      app = "plc"
    }
    annotations = {
      "nginx.ingress.kubernetes.io/rewrite-target" = "/"
    }
  }

  spec {
    rule {
      host = "plc-${var.partition}.${var.domain}"
      http {
        path {
          path = "/"
          path_type = "Prefix"
          backend {
            service {
              name = "plc-${var.partition}"
              port {
                number = 3000
              }
            }
          }
        }
      }
    }
  }
}