# # RBAC for CloudNativePG to access backup credentials
# # The PostgreSQL cluster pods need permission to read the S3 credentials secret

# resource "kubernetes_role" "postgres_backup_secret_reader" {
#   metadata {
#     name      = "postgres-backup-secret-reader"
#     namespace = kubernetes_namespace.databases.metadata[0].name
#   }

#   rule {
#     api_groups = [""]
#     resources  = ["secrets"]
#     resource_names = [
#       kubernetes_secret.postgres_backup_s3.metadata[0].name
#     ]
#     verbs = ["get", "list", "watch"]
#   }
# }

# resource "kubernetes_role_binding" "postgres_backup_secret_reader" {
#   metadata {
#     name      = "postgres-backup-secret-reader"
#     namespace = kubernetes_namespace.databases.metadata[0].name
#   }

#   role_ref {
#     api_group = "rbac.authorization.k8s.io"
#     kind      = "Role"
#     name      = kubernetes_role.postgres_backup_secret_reader.metadata[0].name
#   }

#   subject {
#     kind      = "ServiceAccount"
#     name      = "postgres-cluster"  # CloudNativePG creates a SA named after the cluster
#     namespace = kubernetes_namespace.databases.metadata[0].name
#   }
# }
