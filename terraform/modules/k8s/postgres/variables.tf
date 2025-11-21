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

variable "plc_db_password" {
  description = "PostgreSQL password for PLC user"
  type        = string
  sensitive   = true
  default     = ""
}

variable "postgres_instances" {
  description = "Number of PostgreSQL instances in the cluster"
  type        = number
  default     = 3
}

variable "postgres_storage_size" {
  description = "Storage size for each PostgreSQL instance"
  type        = string
  default     = "10Gi"
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

variable "postgres_cluster_name" {
  description = "PostgreSQL cluster name (increment version for recovery: postgres-cluster-v2, v3, etc.)"
  type        = string
  default     = "postgres-cluster"
}

variable "recovery_source_cluster_name" {
  description = "Source cluster name to recover FROM (usually the original: postgres-cluster)"
  type        = string
  default     = "postgres-cluster-old"
}

variable "enable_recovery" {
  description = "Enable recovery from S3 backup instead of fresh initdb (false for first deployment, true for disaster recovery)"
  type        = bool
  default     = false
}

variable "archive_timeout" {
  description = "PostgreSQL WAL archive timeout - controls RPO (Recovery Point Objective)"
  type        = string
  default     = "1h" # TODO: Consider reducing to 5min for lower RPO in production
}
