variable "keys" {
  description = "Cloud provider keys for external-dns"
  type        = map(string)
  sensitive   = true
}

variable "cluster_domain" {
  description = "Full cluster domain (subdomain.domain)"
  type        = string
}

variable "dns_provider" {
  description = "Cloud provider name"
  type        = string
}
