# External-DNS Configuration
variable "external_dns_access_key" {
  description = "Scaleway access key for external-dns"
  type        = string
  sensitive   = true
}

variable "external_dns_secret_key" {
  description = "Scaleway secret key for external-dns"
  type        = string
  sensitive   = true
}

# Ingress-Nginx Configuration
variable "ingress_nginx_zones" {
  description = "List of zones for load balancer deployment"
  type        = list(string)
}

variable "cluster_domain" {
  description = "Full cluster domain (subdomain.domain)"
  type        = string
}

# Cert-Manager Configuration
variable "cert_manager_acme_email" {
  description = "Email for ACME registration"
  type        = string
}
