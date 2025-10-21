variable "scw_access_key" {
  description = "Scaleway access key for cert-manager DNS01 challenge"
  type        = string
  sensitive   = true
}

variable "scw_secret_key" {
  description = "Scaleway secret key for cert-manager DNS01 challenge"
  type        = string
  sensitive   = true
}

variable "acme_email" {
  description = "Email for ACME registration (Let's Encrypt notifications)"
  type        = string
}
