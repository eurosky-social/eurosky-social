variable "namespace" {
  description = "Namespace for PDS deployment"
  type        = string
  default     = "pds"
}

variable "cluster_domain" {
  description = "Cluster domain for ingress"
  type        = string
}

variable "cert_manager_issuer" {
  description = "cert-manager ClusterIssuer to use for TLS certificates"
  type        = string
}

variable "storage_provisioner" {
  description = "Storage provisioner for PDS volumes"
  type        = string
}

variable "backup_bucket" {
  description = "S3 bucket for Litestream backups"
  type        = string
}

variable "backup_region" {
  description = "S3 region for backup bucket"
  type        = string
}

variable "backup_endpoint" {
  description = "S3 endpoint URL for backup bucket"
  type        = string
}

variable "backup_access_key" {
  description = "S3 access key for Litestream backups"
  type        = string
  sensitive   = true
}

variable "backup_secret_key" {
  description = "S3 secret key for Litestream backups"
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

variable "pds_recovery_did_key" {
  description = "Recovery DID key (did:key format) - additional PDS-controlled recovery mechanism"
  type        = string
  sensitive   = true
  default     = ""
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

variable "pds_version" {
  description = "PDS version"
  type        = string
  default     = "0.4.0"
}

variable "pds_storage_size" {
  description = "PDS storage size"
  type        = string
  default     = "10Gi"
}

variable "pds_did_plc_url" {
  description = "PLC directory URL for DID resolution"
  type        = string
}

variable "pds_bsky_app_view_url" {
  description = "Bluesky App View URL"
  type        = string
}

variable "pds_bsky_app_view_did" {
  description = "Bluesky App View DID"
  type        = string
}

variable "pds_mod_service_url" {
  description = "Moderation service URL (Ozone) for takedowns and moderation actions"
  type        = string
}

variable "pds_mod_service_did" {
  description = "Moderation service DID (Ozone) for takedowns and moderation actions"
  type        = string
}

variable "pds_blob_upload_limit" {
  description = "Maximum blob upload size in bytes"
  type        = string
}

variable "pds_log_enabled" {
  description = "Enable logging"
  type        = string
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
  description = "Public hostname for PDS (e.g., pds.eurosky.social)"
  type        = string
  default     = null
}
