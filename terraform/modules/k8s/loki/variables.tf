variable "storage_class" {
  description = "Storage class for Loki persistent volumes"
  type        = string
}

variable "s3_bucket" {
  description = "S3 bucket name for Loki log storage"
  type        = string
}

variable "s3_region" {
  description = "S3 region for Loki log storage"
  type        = string
}

variable "s3_endpoint" {
  description = "S3 endpoint URL for Loki log storage"
  type        = string
}

variable "s3_access_key" {
  description = "S3 access key for Loki log storage"
  type        = string
  sensitive   = true
}

variable "s3_secret_key" {
  description = "S3 secret key for Loki log storage"
  type        = string
  sensitive   = true
}

variable "monitoring_namespace" {
  description = "Kubernetes namespace where Prometheus stack is deployed"
  type        = string
  default     = "monitoring"
}
