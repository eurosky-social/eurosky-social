# TODO: consider not managing object storage via Terraform to avoid accidental deletions

# UpCloud Managed Object Storage (S3-compatible)
resource "upcloud_managed_object_storage" "main" {
  name              = var.object_storage_name
  region            = var.object_storage_region
  configured_status = "started"

  # Attach to the private network so K8s cluster can access it
  network {
    family = "IPv4"
    name   = "${var.partition}-object-storage-network"
    type   = "private"
    uuid   = upcloud_network.main.id
  }

  # Protect existing Object Storage from accidental deletion
  lifecycle {
    prevent_destroy = true
  }
}

# Backup bucket for PostgreSQL Barman Cloud backups
resource "upcloud_managed_object_storage_bucket" "backup" {
  service_uuid = upcloud_managed_object_storage.main.id
  name         = var.backup_bucket_name

  lifecycle {
    prevent_destroy = true
  }
}

# PDS blobstore bucket for user-uploaded content
resource "upcloud_managed_object_storage_bucket" "pds_blobstore" {
  service_uuid = upcloud_managed_object_storage.main.id
  name         = var.pds_blobstore_bucket_name

  lifecycle {
    prevent_destroy = true
  }
}

# Backup user - only access to backup bucket
resource "upcloud_managed_object_storage_user" "backup" {
  username     = "${var.partition}-backup-user"
  service_uuid = upcloud_managed_object_storage.main.id
}

resource "upcloud_managed_object_storage_user_access_key" "backup" {
  username     = upcloud_managed_object_storage_user.backup.username
  service_uuid = upcloud_managed_object_storage.main.id
  status       = "Active"
}

# PDS user - only access to PDS blobstore bucket
resource "upcloud_managed_object_storage_user" "pds" {
  username     = "${var.partition}-pds-user"
  service_uuid = upcloud_managed_object_storage.main.id
}

resource "upcloud_managed_object_storage_user_access_key" "pds" {
  username     = upcloud_managed_object_storage_user.pds.username
  service_uuid = upcloud_managed_object_storage.main.id
  status       = "Active"
}

# Backup user policy - restrict to backup bucket only
resource "upcloud_managed_object_storage_policy" "backup" {
  name         = "${var.partition}-backup-policy"
  description  = "Allow read/write access only to backup bucket"
  service_uuid = upcloud_managed_object_storage.main.id

  # IAM policy document (URL-encoded JSON)
  document = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "BackupBucketAccess"
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:GetBucketLocation"
        ]
        Resource = "arn:aws:s3:::${var.backup_bucket_name}"
      },
      {
        Sid    = "BackupObjectAccess"
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject"
        ]
        Resource = "arn:aws:s3:::${var.backup_bucket_name}/*"
      }
    ]
  })
}

# Attach backup policy to backup user
resource "upcloud_managed_object_storage_user_policy" "backup" {
  username     = upcloud_managed_object_storage_user.backup.username
  service_uuid = upcloud_managed_object_storage.main.id
  name         = upcloud_managed_object_storage_policy.backup.name
}

# PDS user policy - restrict to PDS blobstore bucket only
resource "upcloud_managed_object_storage_policy" "pds" {
  name         = "${var.partition}-pds-policy"
  description  = "Allow read/write access only to PDS blobstore bucket"
  service_uuid = upcloud_managed_object_storage.main.id

  # IAM policy document (URL-encoded JSON)
  document = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "PDSBucketAccess"
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:GetBucketLocation"
        ]
        Resource = "arn:aws:s3:::${var.pds_blobstore_bucket_name}"
      },
      {
        Sid    = "PDSObjectAccess"
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject"
        ]
        Resource = "arn:aws:s3:::${var.pds_blobstore_bucket_name}/*"
      }
    ]
  })
}

# Attach PDS policy to PDS user
resource "upcloud_managed_object_storage_user_policy" "pds" {
  username     = upcloud_managed_object_storage_user.pds.username
  service_uuid = upcloud_managed_object_storage.main.id
  name         = upcloud_managed_object_storage_policy.pds.name
}
