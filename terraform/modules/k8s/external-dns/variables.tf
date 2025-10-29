variable "api_token" {
  description = "Cloudflare API token for external-dns"
  type        = string
  sensitive   = true
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
