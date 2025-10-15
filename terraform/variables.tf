variable "ozone_hostname" {
  type = string
}

variable "ozone_server_did" {
  type      = string
  sensitive = true
}

variable "ozone_admin_dids" {
  type      = string
  sensitive = true
}

variable "ozone_admin_password" {
  type      = string
  sensitive = true
}

variable "ozone_signing_key_hex" {
  type      = string
  sensitive = true
}

variable "ozone_did_plc_url" {
  type = string
}

variable "ozone_appview_url" {
  type = string
}

variable "ozone_appview_did" {
  type = string
}

variable "plc_directory_url" {
  type = string
}

variable "handle_resolver_url" {
  type = string
}

variable "region" {
  type        = string
  default     = "fr-par"
  description = "Scaleway region for resources"
}

variable "project_id" {
  type        = string
  description = "Scaleway project ID"
}

variable "ozone_image" {
  type        = string
  description = "Ozone container image"
  default     = "ghcr.io/eurosky-social/ozone:latest"
}

variable "ozone_db_password" {
  type        = string
  description = "PostgreSQL password for Ozone database user"
  sensitive   = true
}