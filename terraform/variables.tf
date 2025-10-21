variable "project_id" {
  description = "Scaleway project ID"
  type        = string
}

variable "domain" {
  description = "Base domain for DNS records"
  type        = string
  default     = "eurosky.social"
}

variable "subdomain" {
  description = "Subdomain prefix for this environment"
  type        = string
  default     = "dev" # TODO prod
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
  default     = "ghcr.io/bluesky-social/ozone:latest"
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
