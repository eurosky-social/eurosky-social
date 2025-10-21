variable "zones" {
  description = "List of zones for load balancer deployment"
  type        = list(string)
}

variable "cluster_domain" {
  description = "Full cluster domain (subdomain.domain)"
  type        = string
}

variable "replica_count" {
  description = "Number of ingress-nginx controller replicas"
  type        = number
  default     = 2
}

variable "topology_max_skew" {
  description = "Maximum skew for topology spread constraints"
  type        = number
  default     = 1
}

variable "cloud_provider" {
  description = "Cloud provider (scaleway, aws, gcp, azure)"
  type        = string
  default     = "scaleway"
}
