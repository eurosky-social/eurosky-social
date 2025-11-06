variable "zone" {
  description = "UpCloud zone for resource provisioning"
  type        = string
  default     = "de-fra1"
}

variable "partition" {
  description = "Logical partition name for resources"
  type        = string
}

variable "k8s_node_plan" {
  description = "UpCloud server plan for Kubernetes nodes"
  type        = string
}

variable "k8s_node_count_min" {
  type        = number
  description = "Minimum number of nodes for cluster autoscaler"
}

variable "k8s_node_count_max" {
  type        = number
  description = "Maximum number of nodes for cluster autoscaler"
}

variable "autoscaler_username" {
  type = string
}

variable "autoscaler_password" {
  type      = string
  sensitive = true
}

variable "backup_bucket_name" {
  description = "S3 bucket name for backups"
  type        = string
}

variable "pds_blobstore_bucket_name" {
  description = "S3 bucket name for PDS blobstore"
  type        = string
}

variable "object_storage_region" {
  description = "UpCloud Object Storage region"
  type        = string
  default     = "europe-2" # DE-FRA1
}

variable "object_storage_name" {
  description = "Name of existing UpCloud Managed Object Storage instance"
  type        = string
}

variable "ip_network_range" {
  description = "CIDR range used by the cluster SDN network"
  type        = string
  default     = "172.16.0.0/24"
}

variable "ingress_hostnames" {
  description = "List of hostnames to include in the Load Balancer TLS certificate"
  type        = list(string)
  default     = []
}
