
variable "external_dns_access_key" {
  description = "Scaleway access key for external-dns"
  type        = string
  sensitive   = true
}

variable "external_dns_secret_key" {
  description = "Scaleway secret key for external-dns"
  type        = string
  sensitive   = true
}

variable "ingress_nginx_zones" {
  description = "List of zones for load balancer deployment"
  type        = list(string)
}

variable "cluster_domain" {
  description = "Full cluster domain (subdomain.domain)"
  type        = string
}

variable "cert_manager_acme_email" {
  description = "Email for ACME registration"
  type        = string
}

variable "elasticsearch_storage_class" {
  description = "Storage class for Elasticsearch persistent volumes"
  type        = string
}

variable "kubeconfig_host" {
  description = "Kubernetes API server host from kubeconfig"
  type        = string
}

variable "kubeconfig_token" {
  description = "Kubernetes API server token from kubeconfig"
  type        = string
  sensitive   = true
}

variable "kubeconfig_cluster_ca_certificate" {
  description = "Kubernetes cluster CA certificate from kubeconfig"
  type        = string
  sensitive   = true
}

variable "postgres_storage_class" {
  description = "Storage class for PostgreSQL persistent volumes"
  type        = string
}

variable "postgres_backup_access_key" {
  description = "S3 access key for PostgreSQL backups"
  type        = string
  sensitive   = true
}

variable "postgres_backup_secret_key" {
  description = "S3 secret key for PostgreSQL backups"
  type        = string
  sensitive   = true
}

variable "postgres_backup_destination_path" {
  description = "S3 destination path for PostgreSQL backups"
  type        = string
}

variable "postgres_backup_endpoint_url" {
  description = "S3 endpoint URL for PostgreSQL backups"
  type        = string
}
