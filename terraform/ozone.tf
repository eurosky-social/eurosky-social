# data "kubernetes_secret_v1" "postgres_ca" {
#   metadata {
#     name      = "postgres-cluster-ca"
#     namespace = "databases"
#   }
# }

# resource "kubernetes_secret_v1" "postgres_ca_copy" {
#   metadata {
#     name      = "postgres-ca"
#     namespace = "default"
#   }

#   data = {
#     "ca.crt" = data.kubernetes_secret_v1.postgres_ca.data["ca.crt"]
#   }
# }

# resource "kubernetes_config_map_v1" "ozone" {
#   metadata {
#     name      = "ozone-config"
#     namespace = "default"
#   }

#   data = {
#     NODE_ENV             = "production"
#     LOG_ENABLED          = "true"
#     LOG_LEVEL            = "info"
#     OZONE_DB_MIGRATE     = "1"
#     OZONE_PUBLIC_URL     = "https://${scaleway_domain_record.ozone.name}.${scaleway_domain_record.ozone.dns_zone}"
#     OZONE_DID_PLC_URL    = "https://plc.directory"
#     PLC_DIRECTORY_URL    = "https://plc.directory"
#     HANDLE_RESOLVER_URL  = "https://bsky.social"
#     NODE_EXTRA_CA_CERTS  = "/var/run/postgresql/ca.crt" # Trust CloudNativePG CA certificate

#     OZONE_APPVIEW_URL = var.ozone_appview_url
#     OZONE_APPVIEW_DID = var.ozone_appview_did
#     OZONE_SERVER_DID  = var.ozone_server_did
#     OZONE_ADMIN_DIDS  = var.ozone_admin_dids
#   }
# }

# resource "kubernetes_secret_v1" "ozone" {
#   metadata {
#     name      = "ozone-secrets"
#     namespace = "default"
#   }

#   data = {
#     OZONE_DB_POSTGRES_URL = "postgresql://ozone:${var.ozone_db_password}@postgres-cluster-rw.databases.svc.cluster.local:5432/ozone?sslmode=require"
#     OZONE_ADMIN_PASSWORD  = var.ozone_admin_password
#     OZONE_SIGNING_KEY_HEX = var.ozone_signing_key_hex
#   }
# }

# resource "kubernetes_deployment_v1" "ozone" {
#   metadata {
#     name      = "ozone"
#     namespace = "default"
#     labels = {
#       app = "ozone"
#     }
#   }

#   spec {
#     replicas = 3

#     selector {
#       match_labels = {
#         app = "ozone"
#       }
#     }

#     template {
#       metadata {
#         labels = {
#           app = "ozone"
#         }
#       }

#       spec {
#         topology_spread_constraint {
#           max_skew           = 1
#           topology_key       = "topology.kubernetes.io/zone"
#           when_unsatisfiable = "DoNotSchedule"
#           label_selector {
#             match_labels = {
#               app = "ozone"
#             }
#           }
#         }

#         affinity {
#           pod_anti_affinity {
#             preferred_during_scheduling_ignored_during_execution {
#               weight = 100
#               pod_affinity_term {
#                 label_selector {
#                   match_expressions {
#                     key      = "app"
#                     operator = "In"
#                     values   = ["ozone"]
#                   }
#                 }
#                 topology_key = "kubernetes.io/hostname"
#               }
#             }
#           }
#         }

#         container {
#           name  = "ozone"
#           image = var.ozone_image

#           port {
#             container_port = 3000
#             name           = "http"
#           }

#           env_from {
#             config_map_ref {
#               name = kubernetes_config_map_v1.ozone.metadata[0].name
#             }
#           }

#           env_from {
#             secret_ref {
#               name = kubernetes_secret_v1.ozone.metadata[0].name
#             }
#           }

#           volume_mount {
#             name       = "postgres-ca"
#             mount_path = "/var/run/postgresql"
#             read_only  = true
#           }

#           resources {
#             requests = {
#               cpu    = "200m"
#               memory = "250Mi"
#             }
#             limits = {
#               cpu    = "500m"
#               memory = "500Mi"
#             }
#           }

#           liveness_probe {
#             http_get {
#               path = "/"
#               port = 3000
#             }
#             initial_delay_seconds = 30
#             period_seconds        = 10
#             timeout_seconds       = 5
#             failure_threshold     = 3
#           }

#           readiness_probe {
#             http_get {
#               path = "/"
#               port = 3000
#             }
#             initial_delay_seconds = 10
#             period_seconds        = 5
#             timeout_seconds       = 3
#             failure_threshold     = 3
#           }
#         }

#         volume {
#           name = "postgres-ca"
#           secret {
#             secret_name = kubernetes_secret_v1.postgres_ca_copy.metadata[0].name
#             items {
#               key  = "ca.crt"
#               path = "ca.crt"
#             }
#           }
#         }
#       }
#     }
#   }
# }

# resource "kubernetes_service_v1" "ozone" {
#   metadata {
#     name      = "ozone"
#     namespace = "default"
#     labels = {
#       app = "ozone"
#     }
#   }

#   spec {
#     selector = {
#       app = "ozone"
#     }

#     port {
#       port        = 80
#       target_port = 3000
#       protocol    = "TCP"
#       name        = "http"
#     }

#     type = "ClusterIP"
#   }
# }

# resource "kubernetes_ingress_v1" "ozone" {
#   metadata {
#     name      = "ozone"
#     namespace = "default"
#     annotations = {
#       "cert-manager.io/cluster-issuer"                                = "letsencrypt-prod"
#       "nginx.ingress.kubernetes.io/ssl-redirect"                      = "true"
#       "acme.cert-manager.io/http01-edit-in-place"                     = "true"
#     }
#   }

#   spec {
#     ingress_class_name = "nginx"

#     tls {
#       hosts       = ["${scaleway_domain_record.ozone.name}.${scaleway_domain_record.ozone.dns_zone}"]
#       secret_name = "ozone-tls"
#     }

#     rule {
#       host = "${scaleway_domain_record.ozone.name}.${scaleway_domain_record.ozone.dns_zone}"

#       http {
#         path {
#           path      = "/"
#           path_type = "Prefix"

#           backend {
#             service {
#               name = kubernetes_service_v1.ozone.metadata[0].name
#               port {
#                 number = 80
#               }
#             }
#           }
#         }
#       }
#     }
#   }
# }

# resource "kubernetes_horizontal_pod_autoscaler_v2" "ozone" {
#   metadata {
#     name      = "ozone"
#     namespace = "default"
#   }

#   spec {
#     scale_target_ref {
#       api_version = "apps/v1"
#       kind        = "Deployment"
#       name        = kubernetes_deployment_v1.ozone.metadata[0].name
#     }

#     min_replicas = 2
#     max_replicas = 3

#     metric {
#       type = "Resource"
#       resource {
#         name = "cpu"
#         target {
#           type                = "Utilization"
#           average_utilization = 70 
#         }
#       }
#     }

#     metric {
#       type = "Resource"
#       resource {
#         name = "memory"
#         target {
#           type                = "Utilization"
#           average_utilization = 80 
#         }
#       }
#     }

#     behavior {
#       scale_up {
#         stabilization_window_seconds = 60
#         select_policy                = "Max"
#         policy {
#           type           = "Percent"
#           value          = 50
#           period_seconds = 60
#         }
#         policy {
#           type           = "Pods"
#           value          = 2
#           period_seconds = 60
#         }
#       }

#       scale_down {
#         stabilization_window_seconds = 300
#         select_policy                = "Min"
#         policy {
#           type           = "Percent"
#           value          = 10
#           period_seconds = 60
#         }
#         policy {
#           type           = "Pods"
#           value          = 1
#           period_seconds = 120
#         }
#       }
#     }
#   }
# }
