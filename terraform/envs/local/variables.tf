# DNS and Domain
variable "cluster_domain" {
  description = "Base domain for the local cluster (e.g., local-k8s.u-at-proto.work)"
  type        = string
}

variable "zones" {
  description = "Availability zones (not applicable for k3d, but required by module)"
  type        = list(string)
  default     = ["local"]
}

variable "environment_partition" {
  description = "The partition for the current environment (e.g., 'local', 'dev', 'prod')."
  type        = string
  default     = "local"
}

# Cloudflare Configuration
variable "cloudflare_api_token" {
  description = "Cloudflare API token for external-dns"
  type        = string
  sensitive   = true
}

variable "cloudflare_email" {
  description = "Cloudflare email for external-dns"
  type        = string
  sensitive   = true
}

# Certificate Manager
variable "cert_manager_acme_email" {
  description = "Email for ACME registration (Let's Encrypt)"
  type        = string
  default     = "admin@eurosky.social"
}

variable "ozone_cert_manager_issuer" {
  description = "cert-manager ClusterIssuer for Ozone"
  type        = string
  default     = "letsencrypt-staging"
}

variable "pds_cert_manager_issuer" {
  description = "cert-manager ClusterIssuer for PDS"
  type        = string
  default     = "letsencrypt-staging"
}

variable "kibana_cert_manager_issuer" {
  description = "cert-manager ClusterIssuer for Kibana"
  type        = string
  default     = "letsencrypt-staging"
}

# Storage Configuration
variable "elasticsearch_storage_class" {
  description = "Kubernetes storage class for Elasticsearch"
  type        = string
  default     = "local-path"
}

variable "postgres_storage_class" {
  description = "Kubernetes storage class for PostgreSQL"
  type        = string
  default     = "local-path"
}

variable "pds_storage_provisioner" {
  description = "Storage provisioner for PDS (k3d uses rancher.io/local-path)"
  type        = string
  default     = "rancher.io/local-path"
}

variable "pds_storage_size" {
  description = "PDS storage size"
  type        = string
  default     = "5Gi"
}

# Ozone Configuration
variable "ozone_image" {
  description = "Docker image for Ozone"
  type        = string
  default     = "ghcr.io/bluesky-social/ozone:latest"
}

variable "ozone_public_hostname" {
  description = "Public hostname for Ozone (optional)"
  type        = string
  default     = null
}

variable "ozone_appview_url" {
  description = "Appview URL for Ozone"
  type        = string
  default     = "https://api.bsky.app"
}

variable "ozone_appview_did" {
  description = "Appview DID for Ozone"
  type        = string
  default     = "did:web:api.bsky.app"
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
  description = "PostgreSQL password for Ozone"
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

# PDS Configuration
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
  description = "S3/MinIO bucket for PDS blobstore"
  type        = string
  default     = "pds-blobstore"
}

variable "pds_blobstore_access_key" {
  description = "S3/MinIO access key for PDS blobstore"
  type        = string
  default     = "minioadmin"
  sensitive   = true
}

variable "pds_blobstore_secret_key" {
  description = "S3/MinIO secret key for PDS blobstore"
  type        = string
  default     = "minioadmin"
  sensitive   = true
}

variable "pds_did_plc_url" {
  description = "PLC directory URL for DID resolution"
  type        = string
  default     = "https://plc.directory"
}

variable "pds_bsky_app_view_url" {
  description = "Bluesky App View URL"
  type        = string
  default     = "https://api.bsky.app"
}

variable "pds_bsky_app_view_did" {
  description = "Bluesky App View DID"
  type        = string
  default     = "did:web:api.bsky.app"
}

variable "pds_report_service_url" {
  description = "Moderation/reporting service URL (Ozone)"
  type        = string
  default     = "https://mod.bsky.app"
}

variable "pds_report_service_did" {
  description = "Moderation/reporting service DID (Ozone)"
  type        = string
  default     = "did:plc:ar7c4by46qjdydhdevvrndac"
}

variable "pds_blob_upload_limit" {
  description = "Maximum blob upload size in bytes"
  type        = string
  default     = "52428800"
}

variable "pds_log_enabled" {
  description = "Enable logging"
  type        = string
  default     = "true"
}

variable "pds_email_from_address" {
  description = "Email from address for PDS notifications"
  type        = string
  default     = ""
}

variable "pds_email_smtp_url" {
  description = "SMTP URL for email sending"
  type        = string
  sensitive   = true
  default     = ""
}

variable "pds_public_hostname" {
  description = "Public hostname for PDS (optional)"
  type        = string
  default     = null
}

variable "postgres_cluster_name" {
  description = "The name of the PostgreSQL cluster."
  type        = string
  default     = "postgres-cluster"
}

variable "plc_db_password" {
  description = "The password for the PLC database user."
  type        = string
  default     = "plc_password"
}

variable "enable_plc" {
  description = "Whether to deploy the PLC service."
  type        = bool
  default     = true
}

variable "enable_pds" {
  description = "Whether to deploy the PDS service."
  type        = bool
  default     = true
}

# Prometheus Configuration
variable "prometheus_grafana_admin_password" {
  description = "Grafana admin password for Prometheus stack"
  type        = string
  sensitive   = true
}

variable "prometheus_storage_class" {
  description = "Storage class for Prometheus stack persistent volumes"
  type        = string
  default     = "local-path"
}
