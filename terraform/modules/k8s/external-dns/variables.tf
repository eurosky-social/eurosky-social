variable "access_key" {
  description = "Cloud provider access key for external-dns"
  type        = string
  sensitive   = true
}

variable "secret_key" {
  description = "Cloud provider secret key for external-dns"
  type        = string
  sensitive   = true
}

variable "cluster_domain" {
  description = "Full cluster domain (subdomain.domain)"
  type        = string
}

variable "cloud_provider" {
  description = "Cloud provider (scaleway, aws, gcp, azure)"
  type        = string
  default     = "scaleway"
}

variable "sync_policy" {
  description = "external-dns sync policy (sync or upsert-only)"
  type        = string
  default     = "sync"
}

variable "txt_owner_id" {
  description = "TXT record owner ID"
  type        = string
  default     = "k8s-external-dns"
}

variable "txt_prefix" {
  description = "TXT record prefix"
  type        = string
  default     = "_external-dns."
}

variable "log_level" {
  description = "Log level (debug, info, warn, error)"
  type        = string
  default     = "info"
}

variable "log_format" {
  description = "Log format (text or json)"
  type        = string
  default     = "json"
}

variable "resources_requests_cpu" {
  description = "CPU resource requests"
  type        = string
  default     = "50m"
}

variable "resources_requests_memory" {
  description = "Memory resource requests"
  type        = string
  default     = "64Mi"
}

variable "resources_limits_cpu" {
  description = "CPU resource limits"
  type        = string
  default     = "200m"
}

variable "resources_limits_memory" {
  description = "Memory resource limits"
  type        = string
  default     = "128Mi"
}
