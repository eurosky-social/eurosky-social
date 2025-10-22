variable "namespace" {
  description = "Namespace for Ozone deployment"
  type        = string
  default     = "ozone"
}

variable "cluster_domain" {
  description = "Cluster domain for ingress"
  type        = string
}

variable "cert_manager_issuer" {
  description = "cert-manager ClusterIssuer to use for TLS certificates"
  type        = string
}

variable "ozone_public_hostname" {
  description = "Public hostname for Ozone (e.g., ozone.eurosky.social). If set, derives URL and DID."
  type        = string
  default     = null
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
  description = "Server DID for Ozone (e.g., did:plc:... or did:web:...)"
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

variable "postgres_namespace" {
  description = "PostgreSQL namespace"
  type        = string
}

variable "postgres_cluster_name" {
  description = "PostgreSQL cluster name"
  type        = string
}

variable "postgres_ca_secret_name" {
  description = "PostgreSQL CA secret name"
  type        = string
}
