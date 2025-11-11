output "bucket_name" {
  description = "Name of the created S3 bucket"
  value       = upcloud_managed_object_storage_bucket.bucket.name
}

output "access_key_id" {
  description = "S3 access key ID for the IAM user"
  value       = upcloud_managed_object_storage_user_access_key.key.access_key_id
  sensitive   = true
}

output "secret_access_key" {
  description = "S3 secret access key for the IAM user"
  value       = upcloud_managed_object_storage_user_access_key.key.secret_access_key
  sensitive   = true
}

output "user_name" {
  description = "Name of the IAM user"
  value       = upcloud_managed_object_storage_user.user.username
}
