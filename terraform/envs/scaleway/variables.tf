variable "project_id" {
  description = "Scaleway project ID"
  type        = string
}

variable "cluster_domain" {
  description = "Base domain for DNS records"
  type        = string
}

variable "partition" {
  description = "Logical partition name for resources"
  type        = string
}

variable "cloudflare_dns_api_token" {
  description = "Cloudflare API token for DNS management"
  type        = string
  sensitive   = true
}

variable "ozone_cert_manager_issuer" {
  description = "cert-manager ClusterIssuer for Ozone (letsencrypt-staging or letsencrypt-prod)"
  type        = string
}

variable "pds_cert_manager_issuer" {
  description = "cert-manager ClusterIssuer for PDS (letsencrypt-staging or letsencrypt-prod)"
  type        = string
}

variable "k8s_node_type" {
  description = "Kubernetes node instance type (DEV1-M for dev, PRO2-M for production)"
  type        = string
}

variable "k8s_node_min_size" {
  description = "Minimum number of nodes per pool"
  type        = number
}

variable "k8s_node_max_size" {
  description = "Maximum number of nodes per pool (for autoscaling)"
  type        = number
}

variable "pds_storage_size" {
  description = "PDS storage size (e.g., 10Gi for dev, 100Gi for production)"
  type        = string
}

variable "postgres_storage_class" {
  description = "Kubernetes storage class for PostgreSQL persistent volumes"
  type        = string
}

variable "region" {
  description = "Scaleway region for VPC and cluster resources (must match zone prefix)"
  type        = string
  default     = "fr-par"
}

variable "zones" {
  description = "List of availability zones for deployment"
  type        = list(string)
  default     = ["fr-par-1", "fr-par-2"]
}

variable "cert_manager_acme_email" {
  description = "Email for ACME registration (Let's Encrypt)"
  type        = string
  default     = "admin@eurosky.social"
}

variable "ozone_image" {
  description = "Docker image for Ozone"
  type        = string
  # TODO: Pin to specific SHA or version tag instead of :latest for production (e.g., ghcr.io/bluesky-social/ozone:v1.0.0 or @sha256:abc123...)
  default = "ghcr.io/bluesky-social/ozone:latest"
}

variable "ozone_public_hostname" {
  description = "Public hostname for Ozone (optional, defaults to ozone.<subdomain>.<domain>)"
  type        = string
  default     = null
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
  description = "Server DID for Ozone (e.g., did:plc:... or did:web:...)"
  type        = string
}

variable "ozone_db_password" {
  description = "PostgreSQL password for Ozone (store in tfvars for DR/portability)"
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

variable "pds_dpop_secret" {
  description = "DPoP secret for OAuth token binding (32-byte hex)"
  type        = string
  sensitive   = true
}

variable "pds_recovery_did_key" {
  description = "Recovery DID key (did:key format) - additional PDS-controlled recovery mechanism"
  type        = string
  sensitive   = true
  default     = ""
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
  description = "SMTP URL for email sending (format: smtps://user:pass@host:port/)"
  type        = string
  sensitive   = true
  default     = ""
}

variable "pds_moderation_email_address" {
  description = "Email from address for admin moderation communications"
  type        = string
  default     = ""
}

variable "pds_moderation_email_smtp_url" {
  description = "SMTP URL for moderation emails (format: smtps://user:pass@host:port/)"
  type        = string
  sensitive   = true
  default     = ""
}

variable "pds_public_hostname" {
  description = "Public hostname for PDS (optional, e.g., pds.eurosky.social for prod)"
  type        = string
  default     = null
}

variable "backup_bucket_name" {
  description = "Backup bucket name (must be pre-created)"
  type        = string
}

variable "pds_blobstore_bucket_name" {
  description = "PDS blobstore bucket name (must be pre-created)"
  type        = string
}

variable "postgres_cluster_name" {
  description = "PostgreSQL cluster name (increment version for recovery: postgres-cluster-v2, v3, etc.)"
  type        = string
  default     = "postgres-cluster"
}

variable "postgres_recovery_source_cluster_name" {
  description = "Source cluster name to recover FROM (usually the original: postgres-cluster)"
  type        = string
  default     = "postgres-cluster-old"
}

variable "postgres_enable_recovery" {
  description = "Enable recovery from S3 backup instead of fresh initdb (false for first deployment, true for disaster recovery)"
  type        = bool
  default     = false
}

variable "prometheus_grafana_admin_password" {
  description = "Grafana admin password for Prometheus stack"
  type        = string
  sensitive   = true
}

variable "prometheus_storage_class" {
  description = "Storage class for Prometheus stack persistent volumes"
  type        = string
}

variable "loki_storage_class" {
  description = "Storage class for Loki persistent volumes"
  type        = string
}

variable "alert_email" {
  description = "Email address for Alertmanager notifications"
  type        = string
  default     = "alerts@example.com"
}

variable "smtp_server" {
  description = "SMTP server hostname for alert notifications"
  type        = string
  default     = "smtp.example.com"
}

variable "smtp_port" {
  description = "SMTP server port"
  type        = number
  default     = 587
}

variable "smtp_require_tls" {
  description = "Require TLS for SMTP connection"
  type        = bool
  default     = true
}

variable "smtp_username" {
  description = "SMTP authentication username"
  type        = string
  sensitive   = true
  default     = "alerts@example.com"
}

variable "smtp_password" {
  description = "SMTP authentication password"
  type        = string
  sensitive   = true
  default     = "changeme"
}

variable "deadmansswitch_url" {
  description = "Webhook URL for dead man's switch heartbeat monitoring (e.g., Healthchecks.io). Leave empty to disable."
  type        = string
  sensitive   = true
  default     = ""
}
