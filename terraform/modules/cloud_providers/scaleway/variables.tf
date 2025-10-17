variable "project_id" {
  description = "Scaleway project ID"
  type        = string
}

variable "domain" {
  description = "Base domain for DNS records"
  type        = string
}

variable "subdomain" {
  description = "Subdomain prefix for this environment"
  type        = string
}

variable "zones" {
  description = "List of availability zones for node pools"
  type        = list(string)
}
