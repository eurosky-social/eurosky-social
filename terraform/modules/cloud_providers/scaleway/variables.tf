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

variable "region" {
  description = "Scaleway region"
  type        = string
}

variable "zones" {
  description = "List of availability zones for node pools"
  type        = list(string)
}

variable "k8s_node_type" {
  description = "Kubernetes node instance type"
  type        = string
}

variable "k8s_node_min_size" {
  description = "Minimum number of nodes per pool"
  type        = number
}

variable "k8s_node_max_size" {
  description = "Maximum number of nodes per pool"
  type        = number
}

variable "backup_bucket_name" {
  description = "Backup bucket name (must be pre-created)"
  type        = string
}

variable "pds_blobstore_bucket_name" {
  description = "PDS blobstore bucket name (must be pre-created)"
  type        = string
}
