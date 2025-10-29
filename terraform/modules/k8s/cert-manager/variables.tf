variable "cloudflare_dns_api_token" {
  description = "Cloudflare API token for cert-manager DNS01 challenge"
  type        = string
  sensitive   = true
}

variable "acme_email" {
  description = "Email for ACME registration (Let's Encrypt notifications)"
  type        = string
}
