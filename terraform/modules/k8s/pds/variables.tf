variable "namespace" {
  description = "Namespace for PDS deployment"
  type        = string
  default     = "pds"
}

variable "cluster_domain" {
  description = "Cluster domain for ingress"
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
