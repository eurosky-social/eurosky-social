data "scaleway_object_bucket" "backups_s3" {
  name   = var.backup_bucket_name
  region = var.region
}

# TODO: Implement S3 lifecycle policy for cost optimization - depending on service!
# e.g.:
#   - 0-30 days: Standard storage (hot access for recent logs/backups)
#   - 30 days - 2 years: Glacier (warm access for historical analysis)
#   - 2+ years: Delete (adjust based on compliance requirements)

resource "scaleway_iam_application" "backups" {
  name        = "unified-backups-${var.subdomain}"
  description = "Unified backup service account (PostgreSQL, Litestream)"

  tags = ["backup", "postgres", "litestream", "loki"]
}

# TODO: Rotate to external secret management
resource "scaleway_iam_api_key" "backups" {
  application_id = scaleway_iam_application.backups.id
  default_project_id = var.project_id
  description    = "API key for unified backups to S3"
}

# TODO: define minimal permissions needed
resource "scaleway_iam_policy" "backups_policy" {
  name           = "unified-backups-policy-${var.subdomain}"
  description    = "Grant S3 access to unified backup application"
  application_id = scaleway_iam_application.backups.id

  rule {
    project_ids = [var.project_id]
    permission_set_names = [
      "ObjectStorageFullAccess"
    ]
  }
}