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
