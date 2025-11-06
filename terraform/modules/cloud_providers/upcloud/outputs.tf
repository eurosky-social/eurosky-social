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

output "object_storage_region" {
  value       = var.object_storage_region
  description = "Object storage region"
}
output "object_storage_endpoint" {
  value       = "https://${one(upcloud_managed_object_storage.main.endpoint).domain_name}"
  description = "S3 endpoint for backup bucket (private network endpoint)"
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

output "backup_s3_bucket" {
  value       = upcloud_managed_object_storage_bucket.backup.name
  description = "Backup S3 bucket name"
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

output "pds_blobstore_s3_bucket" {
  value       = upcloud_managed_object_storage_bucket.pds_blobstore.name
  description = "PDS blobstore bucket name"
}

output "storage_provisioner" {
  value       = "storage.csi.upcloud.com"
  description = "Storage provisioner for persistent volumes"
}

output "zones" {
  value       = [var.zone]
  description = "UpCloud zones used by the cluster"
}

output "ingress_nginx_extra_annotations" {
  value = local.ingress_nginx_extra_annotations
  description = "Extra annotations to add to Ingress-NGINX Load Balancer"
}