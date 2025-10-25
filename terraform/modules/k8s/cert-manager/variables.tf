variable "dns_secrets" {
  description = "DNS provider secrets for cert-manager (map of key names to secret values)"
  type        = map(string)
  sensitive   = true
}

variable "secret_name" {
  description = "Name for the Kubernetes secret containing DNS credentials"
  type        = string
}

variable "solver_config" {
  description = "DNS01 solver configuration (YAML string) - provider-specific structure"
  type        = string
}

variable "acme_email" {
  description = "Email for ACME registration (Let's Encrypt notifications)"
  type        = string
}
