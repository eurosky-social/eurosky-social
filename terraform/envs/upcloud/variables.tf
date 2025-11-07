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

variable "maxmind_license_key" {
  description = "MaxMind license key for GeoIP2 database (get free key at https://www.maxmind.com/en/geolite2/signup)"
  type        = string
  sensitive   = true
}

variable "k8s_node_plan" {
  description = "UpCloud server plan for Kubernetes nodes (e.g., 2xCPU-4GB, 4xCPU-8GB)"
  type        = string
  default     = "2xCPU-4GB" # Minimum for testing - upgrade to 4xCPU-8GB for production
}

variable "autoscaler_username" {
  description = "API username to be used by the Autoscaler"
  type        = string
  sensitive   = true
}

variable "autoscaler_password" {
  description = "API password to be used by the Autoscaler"
  type        = string
  sensitive   = true
}

variable "k8s_node_count_min" {
  description = "Minimum number of nodes for cluster autoscaler"
  type        = number
  default     = 1
}

variable "k8s_node_count_max" {
  description = "Maximum number of nodes for cluster autoscaler"
  type        = number
}

variable "pds_storage_size" {
  description = "PDS storage size (e.g., 10Gi for dev, 100Gi for production)"
  type        = string
  default     = "10Gi"
}

variable "postgres_storage_class" {
  description = "Kubernetes storage class for PostgreSQL persistent volumes"
  type        = string
  default     = "upcloud-block-storage-maxiops" # High-performance storage
}

variable "object_storage_region" {
  description = "UpCloud Object Storage region (e.g., europe-2)"
  type        = string
  default     = "europe-2" # DE-FRA1
}

variable "object_storage_name" {
  description = "Name of existing UpCloud Managed Object Storage instance"
  type        = string
}

variable "zone" {
  description = "UpCloud zone for resources (e.g., de-fra1, nl-ams1, us-chi1, pl-waw1, sg-sin1)"
  type        = string
  default     = "de-fra1"
}

variable "cert_manager_acme_email" {
  description = "Email for ACME registration (Let's Encrypt)"
  type        = string
  default     = "admin@eurosky.social"
}

variable "ozone_image" {
  description = "Docker image for Ozone"
  type        = string
  default     = "ghcr.io/bluesky-social/ozone:latest" # TODO: pin version
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
  default     = "upcloud-block-storage-maxiops"
}

variable "loki_storage_class" {
  description = "Storage class for Loki persistent volumes"
  type        = string
  default     = "upcloud-block-storage-maxiops"
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

variable "relay_admin_password" {
  description = "Admin password for relay admin API"
  type        = string
  sensitive   = true
}

variable "relay_storage_class" {
  description = "Storage class for relay PVC"
  type        = string
}

variable "relay_storage_size" {
  description = "Storage size for relay data"
  type        = string
}
