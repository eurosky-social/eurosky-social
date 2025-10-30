output "cluster_id" {
  value       = upcloud_kubernetes_cluster.main.id
  description = "Kubernetes cluster ID"
}

output "kubeconfig_host" {
  value       = yamldecode(data.upcloud_kubernetes_cluster.main.kubeconfig).clusters[0].cluster.server
  description = "Kubernetes API server URL"
  sensitive   = true
}

output "kubeconfig_client_certificate" {
  value       = yamldecode(data.upcloud_kubernetes_cluster.main.kubeconfig).users[0].user["client-certificate-data"]
  description = "Kubernetes client certificate"
  sensitive   = true
}

output "kubeconfig_client_key" {
  value       = yamldecode(data.upcloud_kubernetes_cluster.main.kubeconfig).users[0].user["client-key-data"]
  description = "Kubernetes client key"
  sensitive   = true
}

output "kubeconfig_cluster_ca_certificate" {
  value       = yamldecode(data.upcloud_kubernetes_cluster.main.kubeconfig).clusters[0].cluster["certificate-authority-data"]
  description = "Kubernetes cluster CA certificate"
  sensitive   = true
}

output "backup_s3_endpoint" {
  value       = "https://${upcloud_managed_object_storage.main.name}.${var.object_storage_region}.upcloudobjects.com"
  description = "S3 endpoint for backup bucket"
}

output "backup_s3_access_key" {
  value       = upcloud_managed_object_storage_user_access_key.backup.access_key_id
  description = "S3 access key ID for backups"
  sensitive   = true
}

output "backup_s3_secret_key" {
  value       = upcloud_managed_object_storage_user_access_key.backup.secret_access_key
  description = "S3 secret access key for backups"
  sensitive   = true
}

output "backup_bucket_name" {
  value       = upcloud_managed_object_storage_bucket.backup.name
  description = "Backup bucket name"
}

output "pds_blobstore_s3_endpoint" {
  value       = "https://${upcloud_managed_object_storage.main.name}.${var.object_storage_region}.upcloudobjects.com"
  description = "S3 endpoint for PDS blobstore"
}

output "pds_blobstore_s3_access_key" {
  value       = upcloud_managed_object_storage_user_access_key.pds.access_key_id
  description = "S3 access key ID for PDS blobstore"
  sensitive   = true
}

output "pds_blobstore_s3_secret_key" {
  value       = upcloud_managed_object_storage_user_access_key.pds.secret_access_key
  description = "S3 secret access key for PDS blobstore"
  sensitive   = true
}

output "pds_blobstore_bucket_name" {
  value       = upcloud_managed_object_storage_bucket.pds_blobstore.name
  description = "PDS blobstore bucket name"
}

output "storage_provisioner" {
  value       = "csi.upcloud.com"
  description = "Storage provisioner for persistent volumes"
}

output "zones" {
  value       = [var.zone]
  description = "UpCloud zones used by the cluster"
}


output "backup_s3_bucket" {
  value       = upcloud_managed_object_storage_bucket.backup.name
  description = "Backup S3 bucket name"
}

output "backup_s3_region" {
  value       = var.object_storage_region
  description = "Backup S3 bucket region"
}

output "pds_blobstore_bucket" {
  value       = upcloud_managed_object_storage_bucket.pds_blobstore.name
  description = "PDS blobstore bucket name"
}

output "pds_blobstore_access_key" {
  value       = upcloud_managed_object_storage_user_access_key.pds.access_key_id
  description = "PDS blobstore access key"
  sensitive   = true
}

output "pds_blobstore_secret_key" {
  value       = upcloud_managed_object_storage_user_access_key.pds.secret_access_key
  description = "PDS blobstore secret key"
  sensitive   = true
}