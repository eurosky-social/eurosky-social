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

variable "smtp_server" {
  description = "SMTP server hostname for alert email notifications"
  type        = string
  default     = "smtp.example.com"
}

variable "smtp_port" {
  description = "SMTP server port"
  type        = number
  default     = 587
}

variable "smtp_require_tls" {
  description = "Require TLS for SMTP connection"
  type        = bool
  default     = true
}

variable "smtp_username" {
  description = "SMTP authentication username"
  type        = string
  sensitive   = true
  default     = "alerts@example.com"
}

variable "smtp_password" {
  description = "SMTP authentication password"
  type        = string
  sensitive   = true
  default     = "changeme"
}

variable "deadmansswitch_url" {
  description = "Webhook URL for dead man's switch heartbeat monitoring (e.g., Healthchecks.io). Leave empty to disable."
  type        = string
  sensitive   = true
  default     = ""
}
