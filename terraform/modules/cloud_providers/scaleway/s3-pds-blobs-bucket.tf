data "scaleway_object_bucket" "pds_blobstore" {
  name   = var.pds_blobstore_bucket_name
  region = var.region
}

resource "scaleway_iam_application" "pds_blobstore" {
  name        = "pds-blobstore-${var.subdomain}"
  description = "PDS blob storage service account"

  tags = ["pds", "blobstore"]
}

resource "scaleway_iam_api_key" "pds_blobstore" {
  application_id = scaleway_iam_application.pds_blobstore.id
  description    = "API key for PDS blob storage"
}

# TODO: define minimal permissions needed
resource "scaleway_iam_policy" "pds_blobstore_policy" {
  name           = "pds-blobstore-policy-${var.subdomain}"
  description    = "Grant S3 access to PDS blobstore application"
  application_id = scaleway_iam_application.pds_blobstore.id

  rule {
    project_ids = [var.project_id]
    permission_set_names = [
      "ObjectStorageFullAccess"
    ]
  }
}
