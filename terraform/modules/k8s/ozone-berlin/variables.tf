variable "cluster_domain" {
  description = "Cluster domain for ingress"
  type        = string
}

variable "ozone_berlin_db_password" {
  description = "PostgreSQL password for Ozone user"
  type        = string
  sensitive   = true
}

variable "ozone_berlin_admin_password" {
  description = "Admin password for Ozone"
  type        = string
  sensitive   = true
}

variable "ozone_berlin_signing_key_hex" {
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
