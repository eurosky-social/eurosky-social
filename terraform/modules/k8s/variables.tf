variable "kubeconfig_host" {
  description = "Kubernetes API server host"
  type        = string
}

variable "kubeconfig_token" {
  description = "Kubernetes authentication token"
  type        = string
  sensitive   = true
}

variable "kubeconfig_cluster_ca_certificate" {
  description = "Kubernetes cluster CA certificate (base64 encoded)"
  type        = string
  sensitive   = true
}

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

variable "backup_storage_class" {
  description = "Storage class for backup-related persistent volumes (PostgreSQL)"
  type        = string
}

variable "backup_s3_access_key" {
  description = "S3 access key for all backups (PostgreSQL, Litestream)"
  type        = string
  sensitive   = true
}

variable "backup_s3_secret_key" {
  description = "S3 secret key for all backups (PostgreSQL, Litestream)"
  type        = string
  sensitive   = true
}

variable "backup_s3_bucket" {
  description = "S3 bucket for all backups (postgres/, litestream/ prefixes)"
  type        = string
}

variable "backup_s3_region" {
  description = "S3 region for backup bucket"
  type        = string
}

variable "backup_s3_endpoint" {
  description = "S3 endpoint URL for backup bucket"
  type        = string
}

variable "ozone_image" {
  description = "Docker image for Ozone"
  type        = string
}

variable "ozone_appview_url" {
  description = "Appview URL for Ozone"
  type        = string
}

variable "ozone_appview_did" {
  description = "Appview DID for Ozone"
  type        = string
}

variable "ozone_server_did" {
  description = "Server DID for Ozone"
  type        = string
}

variable "ozone_admin_dids" {
  description = "Admin DIDs for Ozone (comma-separated)"
  type        = string
}

variable "ozone_db_password" {
  description = "PostgreSQL password for Ozone user"
  type        = string
  sensitive   = true
}

variable "ozone_admin_password" {
  description = "Admin password for Ozone"
  type        = string
  sensitive   = true
}

variable "ozone_signing_key_hex" {
  description = "Signing key (hex) for Ozone"
  type        = string
  sensitive   = true
}

variable "pds_storage_provisioner" {
  description = "Storage provisioner for PDS volumes"
  type        = string
}

variable "pds_jwt_secret" {
  description = "JWT secret for PDS authentication"
  type        = string
  sensitive   = true
}

variable "pds_admin_password" {
  description = "Admin password for PDS"
  type        = string
  sensitive   = true
}

variable "pds_plc_rotation_key" {
  description = "PLC rotation key (K256 private key hex)"
  type        = string
  sensitive   = true
}

variable "pds_blobstore_bucket" {
  description = "S3 bucket for PDS blob storage"
  type        = string
}

variable "pds_blobstore_access_key" {
  description = "S3 access key for PDS blobstore"
  type        = string
  sensitive   = true
}

variable "pds_blobstore_secret_key" {
  description = "S3 secret key for PDS blobstore"
  type        = string
  sensitive   = true
}
