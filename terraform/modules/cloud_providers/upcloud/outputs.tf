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
  value = "https://${[for endpoint in upcloud_managed_object_storage.main.endpoint : endpoint.domain_name if endpoint.type == "private"][0]}"
  description = "S3 endpoint for all buckets (private network endpoint)"
}

# PostgreSQL backup bucket credentials
output "postgres_backup_s3_bucket" {
  value       = module.s3_bucket["postgres-backup"].bucket_name
  description = "PostgreSQL backup S3 bucket name"
}

output "postgres_backup_s3_access_key" {
  value       = module.s3_bucket["postgres-backup"].access_key_id
  description = "S3 access key ID for PostgreSQL backups"
  sensitive   = true
}

output "postgres_backup_s3_secret_key" {
  value       = module.s3_bucket["postgres-backup"].secret_access_key
  description = "S3 secret access key for PostgreSQL backups"
  sensitive   = true
}

# Relay backup bucket credentials
output "relay_backup_s3_bucket" {
  value       = module.s3_bucket["relay-backup"].bucket_name
  description = "Relay backup S3 bucket name"
}

output "relay_backup_s3_access_key" {
  value       = module.s3_bucket["relay-backup"].access_key_id
  description = "S3 access key ID for Relay backups"
  sensitive   = true
}

output "relay_backup_s3_secret_key" {
  value       = module.s3_bucket["relay-backup"].secret_access_key
  description = "S3 secret access key for Relay backups"
  sensitive   = true
}

# PDS backup bucket credentials
output "pds_backup_s3_bucket" {
  value       = module.s3_bucket["pds-backup"].bucket_name
  description = "PDS backup S3 bucket name"
}

output "pds_backup_s3_access_key" {
  value       = module.s3_bucket["pds-backup"].access_key_id
  description = "S3 access key ID for PDS backups"
  sensitive   = true
}

output "pds_backup_s3_secret_key" {
  value       = module.s3_bucket["pds-backup"].secret_access_key
  description = "S3 secret access key for PDS backups"
  sensitive   = true
}

# Loki logs bucket credentials
output "logs_s3_bucket" {
  value       = module.s3_bucket["logs"].bucket_name
  description = "Loki logs S3 bucket name"
}

output "logs_s3_access_key" {
  value       = module.s3_bucket["logs"].access_key_id
  description = "S3 access key ID for Loki logs"
  sensitive   = true
}

output "logs_s3_secret_key" {
  value       = module.s3_bucket["logs"].secret_access_key
  description = "S3 secret access key for Loki logs"
  sensitive   = true
}

# Thanos metrics bucket credentials
output "metrics_s3_bucket" {
  value       = module.s3_bucket["metrics"].bucket_name
  description = "Thanos metrics S3 bucket name"
}

output "metrics_s3_access_key" {
  value       = module.s3_bucket["metrics"].access_key_id
  description = "S3 access key ID for Thanos metrics"
  sensitive   = true
}

output "metrics_s3_secret_key" {
  value       = module.s3_bucket["metrics"].secret_access_key
  description = "S3 secret access key for Thanos metrics"
  sensitive   = true
}

# PDS blobstore bucket credentials
output "pds_blobstore_s3_bucket" {
  value       = module.s3_bucket["pds-blobs"].bucket_name
  description = "PDS blobstore S3 bucket name"
}

output "pds_blobstore_s3_access_key" {
  value       = module.s3_bucket["pds-blobs"].access_key_id
  description = "S3 access key ID for PDS blobstore"
  sensitive   = true
}

output "pds_blobstore_s3_secret_key" {
  value       = module.s3_bucket["pds-blobs"].secret_access_key
  description = "S3 secret access key for PDS blobstore"
  sensitive   = true
}

# PDS Berlin blobstore bucket credentials
output "pds_berlin_blobstore_s3_bucket" {
  value       = module.s3_bucket["pds-berlin-blobs"].bucket_name
  description = "PDS Berlin blobstore S3 bucket name"
}

output "pds_berlin_blobstore_s3_access_key" {
  value       = module.s3_bucket["pds-berlin-blobs"].access_key_id
  description = "S3 access key ID for PDS Berlin blobstore"
  sensitive   = true
}

output "pds_berlin_blobstore_s3_secret_key" {
  value       = module.s3_bucket["pds-berlin-blobs"].secret_access_key
  description = "S3 secret access key for PDS Berlin blobstore"
  sensitive   = true
}

# PDS Berlin backup bucket credentials
output "pds_berlin_backup_s3_bucket" {
  value       = module.s3_bucket["pds-berlin-backup"].bucket_name
  description = "PDS Berlin backup S3 bucket name"
}

output "pds_berlin_backup_s3_access_key" {
  value       = module.s3_bucket["pds-berlin-backup"].access_key_id
  description = "S3 access key ID for PDS Berlin backups"
  sensitive   = true
}

output "pds_berlin_backup_s3_secret_key" {
  value       = module.s3_bucket["pds-berlin-backup"].secret_access_key
  description = "S3 secret access key for PDS Berlin backups"
  sensitive   = true
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
  value       = local.ingress_nginx_extra_annotations
  description = "Extra annotations to add to Ingress-NGINX Load Balancer"
}
