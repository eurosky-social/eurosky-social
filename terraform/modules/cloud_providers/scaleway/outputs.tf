output "zones" {
  description = "Availability zones"
  value       = var.zones
}

<<<<<<< HEAD
=======
output "dns_zone_access_key" {
  description = "Scaleway DNS zone access key (for external-dns and cert-manager)"
  value       = scaleway_iam_api_key.external_dns.access_key
  sensitive   = true
}

output "dns_zone_secret_key" {
  description = "Scaleway DNS zone secret key (for external-dns and cert-manager)"
  value       = scaleway_iam_api_key.external_dns.secret_key
  sensitive   = true
}

>>>>>>> d173284 (WIP)
output "kubeconfig" {
  description = "Kubernetes cluster kubeconfig"
  value       = scaleway_k8s_cluster.kapsule_multi_az.kubeconfig
  sensitive   = true
}

output "kubeconfig_host" {
  description = "Kubernetes API server host (waits for pools to be ready)"
  value       = null_resource.kubeconfig.triggers.host
}

output "kubeconfig_token" {
  description = "Kubernetes API server token (waits for pools to be ready)"
  value       = null_resource.kubeconfig.triggers.token
  sensitive   = true
}

output "kubeconfig_cluster_ca_certificate" {
  description = "Kubernetes cluster CA certificate (waits for pools to be ready)"
  value       = null_resource.kubeconfig.triggers.cluster_ca_certificate
  sensitive   = true
}

output "backup_s3_access_key" {
  description = "Unified backup S3 access key"
  value       = scaleway_iam_api_key.backups.access_key
  sensitive   = true
}

output "backup_s3_secret_key" {
  description = "Unified backup S3 secret key"
  value       = scaleway_iam_api_key.backups.secret_key
  sensitive   = true
}

output "backup_s3_bucket" {
  description = "Unified backup S3 bucket name"
  value       = data.scaleway_object_bucket.backups_s3.name
}

output "backup_s3_region" {
  description = "Unified backup S3 bucket region"
  value       = var.region
}

output "backup_s3_endpoint" {
  description = "Scaleway S3 endpoint URL"
  value       = "https://s3.${var.region}.scw.cloud"
}

output "pds_blobstore_bucket" {
  description = "PDS blobstore S3 bucket name"
  value       = data.scaleway_object_bucket.pds_blobstore.name
}

output "pds_blobstore_access_key" {
  description = "PDS blobstore S3 access key"
  value       = scaleway_iam_api_key.pds_blobstore.access_key
  sensitive   = true
}

output "pds_blobstore_secret_key" {
  description = "PDS blobstore S3 secret key"
  value       = scaleway_iam_api_key.pds_blobstore.secret_key
  sensitive   = true
}


output "cluster_id" {
  description = "Kubernetes cluster ID"
  value       = scaleway_k8s_cluster.kapsule_multi_az.id
}

output "storage_provisioner" {
  description = "Kubernetes CSI storage provisioner"
  value       = local.storage_provisioner
}

