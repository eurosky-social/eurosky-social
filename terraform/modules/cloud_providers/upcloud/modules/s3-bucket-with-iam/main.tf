# Create S3 bucket
resource "upcloud_managed_object_storage_bucket" "bucket" {
  service_uuid = var.service_uuid
  name         = var.bucket_name

  lifecycle {
    prevent_destroy = true
  }
}

# Create IAM user
resource "upcloud_managed_object_storage_user" "user" {
  username     = var.user_name
  service_uuid = var.service_uuid
}

# Create access key for user
resource "upcloud_managed_object_storage_user_access_key" "key" {
  username     = upcloud_managed_object_storage_user.user.username
  service_uuid = var.service_uuid
  status       = "Active"
}

# Create IAM policy restricting access to this bucket only
resource "upcloud_managed_object_storage_policy" "policy" {
  name         = var.policy_name
  description  = "Allow read/write access only to ${var.description} bucket"
  service_uuid = var.service_uuid

  # IAM policy document restricting access to specific bucket
  document = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "${replace(title(replace(var.bucket_name, "-", " ")), " ", "")}BucketAccess"
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:GetBucketLocation",
          "s3:ListAllMyBuckets"
        ]
        Resource = [
          "arn:aws:s3:::${upcloud_managed_object_storage_bucket.bucket.name}",
          "arn:aws:s3:::*"
        ]
      },
      {
        Sid    = "${replace(title(replace(var.bucket_name, "-", " ")), " ", "")}ObjectAccess"
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject"
        ]
        Resource = "arn:aws:s3:::${upcloud_managed_object_storage_bucket.bucket.name}/*"
      }
    ]
  })
}

# Attach policy to user
resource "upcloud_managed_object_storage_user_policy" "attachment" {
  username     = upcloud_managed_object_storage_user.user.username
  service_uuid = var.service_uuid
  name         = upcloud_managed_object_storage_policy.policy.name
}
