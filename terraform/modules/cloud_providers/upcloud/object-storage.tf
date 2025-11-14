# TODO: consider not managing object storage via Terraform to avoid accidental deletions
# Note: requires creating a router -> private network -> object storage service

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

  # Disable public access  
  # network {
  #   family = "IPv4"
  #   name   = "${var.partition}-object-storage-network-pub"
  #   type   = "public"
  # }

  # Protect existing Object Storage from accidental deletion
  lifecycle {
    prevent_destroy = true
  }
}

# Define bucket configuration for all workloads
locals {
  buckets = {
    postgres-backup = {
      description = "PostgreSQL Barman backups"
    }
    relay-backup = {
      description = "Relay SQLite backups"
    }
    pds-backup = {
      description = "PDS SQLite backups"
    }
    logs = {
      description = "Loki log storage"
    }
    metrics = {
      description = "Thanos long-term metrics"
    }
    pds-blobs = {
      description = "PDS user content"
    }
    pds-berlin-blobs = {
      description = "PDS Berlin user content"
    }
    pds-berlin-backup = {
      description = "PDS Berlin SQLite backups"
    }
  }
}

# Create S3 bucket with dedicated IAM user for each workload
module "s3_bucket" {
  source = "./modules/s3-bucket-with-iam"

  for_each = local.buckets

  service_uuid = upcloud_managed_object_storage.main.id
  bucket_name  = "${each.key}-${var.partition}"
  user_name    = "${each.key}-${var.partition}-user"
  policy_name  = "${each.key}-${var.partition}-policy"
  description  = each.value.description
}
