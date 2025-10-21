variable "namespace" {
  description = "Namespace for PostgreSQL cluster"
  type        = string
  default     = "databases"
}

variable "storage_class" {
  description = "Storage class for PostgreSQL persistent volumes"
  type        = string
}

variable "backup_s3_access_key" {
  description = "S3 access key for PostgreSQL backups"
  type        = string
  sensitive   = true
}

variable "backup_s3_secret_key" {
  description = "S3 secret key for PostgreSQL backups"
  type        = string
  sensitive   = true
}

variable "backup_s3_bucket" {
  description = "S3 bucket for PostgreSQL backups"
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

variable "ozone_db_password" {
  description = "PostgreSQL password for Ozone user"
  type        = string
  sensitive   = true
}

variable "cnpg_version" {
  description = "CloudNativePG operator version"
  type        = string
  default     = "0.26.0"
}

variable "barman_plugin_chart_version" {
  description = "Barman Cloud plugin Helm chart version"
  type        = string
  default     = "0.2.0"
}

variable "monitoring_enabled" {
  description = "Enable Prometheus monitoring"
  type        = bool
  default     = false
}
