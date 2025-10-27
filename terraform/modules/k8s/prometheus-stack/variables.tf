variable "grafana_admin_password" {
  description = "Grafana admin password"
  type        = string
  sensitive   = true
}

variable "storage_class" {
  description = "Storage class for Prometheus persistent volumes"
  type        = string
}

variable "cluster_domain" {
  description = "Cluster domain for ingress hostnames"
  type        = string
}

variable "alert_email" {
  description = "Email address to receive alerts from Alertmanager"
  type        = string
}

variable "thanos_s3_bucket" {
  description = "S3 bucket for Thanos long-term metrics storage"
  type        = string
}

variable "thanos_s3_region" {
  description = "S3 region for Thanos bucket"
  type        = string
}

variable "thanos_s3_endpoint" {
  description = "S3 endpoint URL for Thanos"
  type        = string
}

variable "thanos_s3_access_key" {
  description = "S3 access key for Thanos"
  type        = string
  sensitive   = true
}

variable "thanos_s3_secret_key" {
  description = "S3 secret key for Thanos"
  type        = string
  sensitive   = true
}
