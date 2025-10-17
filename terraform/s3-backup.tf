# resource "scaleway_object_bucket" "postgres_backups" {
#   name   = "ozone-postgres-backups-${var.project_id}"
#   region = var.region

#   tags = {
#     purpose    = "postgresql-backups"
#     service    = "ozone"
#     managed_by = "terraform"
#   }

#   lifecycle_rule {
#     id      = "wal-segments-cleanup"
#     enabled = true
#     prefix  = "backups/wals/"

#     expiration {
#       days = 30
#     }
#   }

#   lifecycle_rule {
#     id      = "base-backups-cleanup"
#     enabled = true
#     prefix  = "backups/base/"

#     expiration {
#       days = 35
#     }
#   }
# }

# # S3 Lifecycle Configuration for tiered backup retention
# # Strategy:
# # - WAL segments: 30 days expiration
# # - Base backups: 30 days retention (CloudNativePG retentionPolicy)
# # - No long-term archival (saves ~€100/month for 100k users)

# # IAM application for backup access
# resource "scaleway_iam_application" "postgres_backup" {
#   name        = "ozone-postgres-backup"
#   description = "PostgreSQL backup service account"

#   tags = ["postgres", "backup", "ozone"]
# }

# # API key for the backup application
# resource "scaleway_iam_api_key" "postgres_backup" {
#   application_id = scaleway_iam_application.postgres_backup.id
#   description    = "API key for PostgreSQL backup to S3"
# }

# # Attach policy to application
# resource "scaleway_iam_policy" "postgres_backup_policy" {
#   name           = "ozone-postgres-backup-policy"
#   description    = "Grant S3 access to PostgreSQL backup application"
#   application_id = scaleway_iam_application.postgres_backup.id

#   rule {
#     project_ids = [var.project_id]
#     permission_set_names = [
#       "ObjectStorageObjectsRead",
#       "ObjectStorageObjectsWrite",
#       "ObjectStorageObjectsDelete",
#       "ObjectStorageBucketsRead"
#     ]
#   }
# }

# # Kubernetes secret with S3 credentials for CloudNativePG
# resource "kubernetes_secret" "postgres_backup_s3" {
#   metadata {
#     name      = "postgres-backup-s3-creds"
#     namespace = kubernetes_namespace.databases.metadata[0].name
#   }

#   data = {
#     ACCESS_KEY_ID     = scaleway_iam_api_key.postgres_backup.access_key
#     ACCESS_SECRET_KEY = scaleway_iam_api_key.postgres_backup.secret_key
#   }

#   type = "Opaque"
# }
