output "domain" {
  description = "Base domain for DNS records"
  value       = var.domain
}

output "subdomain" {
  description = "Subdomain prefix"
  value       = var.subdomain
}

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

output "postgres_backup_access_key" {
  description = "PostgreSQL backup S3 access key"
  value       = scaleway_iam_api_key.postgres_backup.access_key
  sensitive   = true
}

output "postgres_backup_secret_key" {
  description = "PostgreSQL backup S3 secret key"
  value       = scaleway_iam_api_key.postgres_backup.secret_key
  sensitive   = true
}

output "postgres_backup_destination_path" {
  description = "PostgreSQL backup S3 destination path"
  value       = "s3://${scaleway_object_bucket.postgres_backups_s3.name}/backups"
}

output "postgres_backup_endpoint_url" {
  description = "PostgreSQL backup S3 endpoint URL"
  value       = scaleway_object_bucket.postgres_backups_s3.api_endpoint
}
