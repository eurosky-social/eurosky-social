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
