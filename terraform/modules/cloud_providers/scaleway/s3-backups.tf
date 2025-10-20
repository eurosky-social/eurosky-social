resource "random_id" "bucket_suffix" {
  # Prevents bucket name conflicts on destroy/recreate cycles
  byte_length = 4

  keepers = {
    project_id = var.project_id
  }
}

resource "scaleway_object_bucket" "backups_s3" {
  name   = "eurosky-backups-${random_id.bucket_suffix.hex}"
  region = var.region

  force_destroy = true

  tags = {
    purpose    = "unified-backups"
    managed_by = "terraform"
  }

  lifecycle_rule {
    id      = "postgres-wal-segments-cleanup"
    enabled = true
    prefix  = "postgres/wals/"

    expiration {
      days = 35
    }
  }

  lifecycle_rule {
    id      = "postgres-base-backups-cleanup"
    enabled = true
    prefix  = "postgres/base/"

    expiration {
      days = 35
    }
  }

  lifecycle_rule {
    id      = "litestream-backups-cleanup"
    enabled = true
    prefix  = "litestream/"

    expiration {
      days = 35
    }
  }
}

resource "scaleway_iam_application" "backups" {
  name        = "unified-backups"
  description = "Unified backup service account (PostgreSQL, Litestream)"

  tags = ["backup", "postgres", "litestream"]
}

resource "scaleway_iam_api_key" "backups" {
  application_id = scaleway_iam_application.backups.id
  description    = "API key for unified backups to S3"
}

resource "scaleway_iam_policy" "backups_policy" {
  name           = "unified-backups-policy"
  description    = "Grant S3 access to unified backup application"
  application_id = scaleway_iam_application.backups.id

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

resource "scaleway_object_bucket" "pds_blobstore" {
  name   = "eurosky-pds-blobs-${random_id.bucket_suffix.hex}"
  region = var.region

  force_destroy = false

  tags = {
    purpose    = "pds-blobstore"
    managed_by = "terraform"
  }
}

resource "scaleway_iam_application" "pds_blobstore" {
  name        = "pds-blobstore"
  description = "PDS blob storage service account"

  tags = ["pds", "blobstore"]
}

resource "scaleway_iam_api_key" "pds_blobstore" {
  application_id = scaleway_iam_application.pds_blobstore.id
  description    = "API key for PDS blob storage"
}

resource "scaleway_iam_policy" "pds_blobstore_policy" {
  name           = "pds-blobstore-policy"
  description    = "Grant S3 access to PDS blobstore application"
  application_id = scaleway_iam_application.pds_blobstore.id

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
