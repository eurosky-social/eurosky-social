resource "random_id" "bucket_suffix" {
  # Prevents bucket name conflicts on destroy/recreate cycles
  byte_length = 4

  keepers = {
    project_id = var.project_id
  }
}

resource "scaleway_object_bucket" "postgres_backups_s3" {
  name   = "ozone-pgbackups-${random_id.bucket_suffix.hex}"
  region = var.region

  force_destroy = true

  tags = {
    purpose    = "postgresql-backups"
    managed_by = "terraform"
  }

  lifecycle_rule {
    id      = "wal-segments-cleanup"
    enabled = true
    prefix  = "backups/wals/"

    expiration {
      days = 35
    }
  }

  lifecycle_rule {
    id      = "base-backups-cleanup"
    enabled = true
    prefix  = "backups/base/"

    expiration {
      days = 35
    }
  }
}

resource "scaleway_iam_application" "postgres_backup" {
  name        = "postgres-backup"
  description = "PostgreSQL backup service account"

  tags = ["postgres", "backup"]
}

resource "scaleway_iam_api_key" "postgres_backup" {
  application_id = scaleway_iam_application.postgres_backup.id
  description    = "API key for PostgreSQL backup to S3"
}

resource "scaleway_iam_policy" "postgres_backup_policy" {
  name           = "postgres-backup-policy"
  description    = "Grant S3 access to PostgreSQL backup application"
  application_id = scaleway_iam_application.postgres_backup.id

  rule {
    project_ids = [var.project_id]
    permission_set_names = [
      "ObjectStorageObjectsRead",
      "ObjectStorageObjectsWrite",
      "ObjectStorageObjectsDelete",
      "ObjectStorageBucketsRead"
    ]
  }
}
