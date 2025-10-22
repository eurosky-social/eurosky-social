output "zones" {
  description = "Availability zones"
  value       = var.zones
}

output "external_dns_access_key" {
  description = "External-DNS Scaleway access key"
  value       = scaleway_iam_api_key.external_dns.access_key
  sensitive   = true
}

output "external_dns_secret_key" {
  description = "External-DNS Scaleway secret key"
  value       = scaleway_iam_api_key.external_dns.secret_key
  sensitive   = true
}

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
  description = "Unified backup S3 endpoint URL"
  value       = data.scaleway_object_bucket.backups_s3.endpoint
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

output "domain" {
  description = "DNS zone (subdomain.domain)"
  value       = scaleway_domain_zone.cluster_subdomain.id
}

output "cluster_id" {
  description = "Kubernetes cluster ID"
  value       = scaleway_k8s_cluster.kapsule_multi_az.id
}

output "storage_provisioner" {
  description = "Kubernetes CSI storage provisioner"
  value       = local.storage_provisioner
}

