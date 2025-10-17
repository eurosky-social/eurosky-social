variable "project_id" {
  description = "Scaleway project ID"
  type        = string
}

variable "domain" {
  description = "Base domain for DNS records"
  type        = string
  default     = "eurosky.social"
}

variable "subdomain" {
  description = "Subdomain prefix for this environment"
  type        = string
  default     = "scw"
}

variable "region" {
  description = "Scaleway region for VPC and cluster resources (must match zone prefix)"
  type        = string
  default     = "fr-par"
}

variable "zones" {
  description = "List of availability zones for deployment"
  type        = list(string)
  default     = ["fr-par-1", "fr-par-2"]
}

variable "cert_manager_acme_email" {
  description = "Email for ACME registration (Let's Encrypt)"
  type        = string
  default     = "admin@eurosky.social"
}
