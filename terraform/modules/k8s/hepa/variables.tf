variable "cluster_domain" {
  description = "Base domain for the cluster"
  type        = string
}

variable "ozone_did" {
  description = "DID for Ozone"
  type        = string
}

variable "ozone_admin_password" {
  description = "Admin password for Ozone"
  type        = string
  sensitive   = true
}

variable "pds_admin_password" {
  description = "Admin password for PDS"
  type        = string
  sensitive   = true
}
