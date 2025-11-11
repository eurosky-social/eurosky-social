variable "enabled" {
  description = "Whether to deploy the PDS service."
  type        = bool
  default     = true
}

variable "partition" {
  description = "The partition for the current environment (e.g., 'local', 'dev', 'prod')."
  type        = string
}

variable "domain" {
  description = "The domain for the cluster."
  type        = string
}

variable "image_name" {
  description = "The name of the PDS Docker image."
  type        = string
  default     = "ghcr.io/bluesky-social/pds"
}

variable "image_tag" {
  description = "The tag of the PDS Docker image."
  type        = string
  default     = "latest"
}

variable "replicas" {
  description = "The number of replicas for the PDS deployment."
  type        = number
  default     = 1
}

variable "pds_admin_password" {
  description = "Admin password for PDS."
  type        = string
  sensitive   = true
}

variable "pds_blobstore_disk_location" {
  description = "PDS blobstore disk location."
  type        = string
  default     = "/app/data/blobs"
}

variable "pds_data_directory" {
  description = "PDS data directory."
  type        = string
  default     = "/app/data"
}

variable "pds_did_plc_url" {
  description = "PLC directory URL for DID resolution."
  type        = string
}

variable "pds_hostname" {
  description = "Hostname for PDS."
  type        = string
}

variable "pds_jwt_secret" {
  description = "JWT secret for PDS authentication."
  type        = string
  sensitive   = true
}

variable "pds_port" {
  description = "PDS service port."
  type        = number
  default     = 3000
}

variable "pds_plc_rotation_key_k256_private_key_hex" {
  description = "PLC rotation key (K256 private key hex)."
  type        = string
  sensitive   = true
}

variable "pds_recovery_did_key" {
  description = "PDS recovery DID key."
  type        = string
}

variable "pds_disable_ssrf_protection" {
  description = "Disable SSRF protection for PDS."
  type        = bool
  default     = true
}

variable "pds_dev_mode" {
  description = "Enable PDS development mode."
  type        = bool
  default     = true
}

variable "pds_invite_required" {
  description = "Require invite code for PDS."
  type        = bool
  default     = false
}

variable "pds_bsky_app_view_url" {
  description = "Bluesky App View URL."
  type        = string
}

variable "pds_bsky_app_view_did" {
  description = "Bluesky App View DID."
  type        = string
}

variable "pds_email_smtp_url" {
  description = "SMTP URL for email sending."
  type        = string
}

variable "pds_email_from_address" {
  description = "Email from address for PDS notifications."
  type        = string
}

variable "pds_moderation_email_smtp_url" {
  description = "SMTP URL for moderation email sending."
  type        = string
}

variable "pds_moderation_email_address" {
  description = "Moderation email address."
  type        = string
}

variable "pds_mod_service_url" {
  description = "Moderation service URL (Ozone)."
  type        = string
}

variable "pds_mod_service_did" {
  description = "Moderation service DID (Ozone)."
  type        = string
}

variable "log_enabled" {
  description = "Enable logging for PDS."
  type        = bool
  default     = true
}

variable "log_level" {
  description = "Log level for PDS."
  type        = string
  default     = "debug"
}
