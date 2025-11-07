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

variable "cluster_domain" {
  description = "Base domain for the cluster"
  type        = string
}
