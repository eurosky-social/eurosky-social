variable "storage_class" {
  description = "Storage class for Elasticsearch persistent volumes"
  type        = string
}

variable "cluster_domain" {
  description = "Full cluster domain for ingress"
  type        = string
}

variable "operator_resources_requests_cpu" {
  description = "ECK operator CPU requests"
  type        = string
  default     = "50m"
}

variable "operator_resources_requests_memory" {
  description = "ECK operator memory requests"
  type        = string
  default     = "100Mi"
}

variable "operator_resources_limits_cpu" {
  description = "ECK operator CPU limits"
  type        = string
  default     = "500m"
}

variable "operator_resources_limits_memory" {
  description = "ECK operator memory limits"
  type        = string
  default     = "256Mi"
}

variable "es_node_count" {
  description = "Elasticsearch node count"
  type        = number
  default     = 1
}

variable "es_storage_size" {
  description = "Elasticsearch storage size per node"
  type        = string
  default     = "2Gi"
}

variable "es_resources_requests_cpu" {
  description = "Elasticsearch CPU requests"
  type        = string
  default     = "100m"
}

variable "es_resources_requests_memory" {
  description = "Elasticsearch memory requests"
  type        = string
  default     = "1Gi"
}

variable "es_resources_limits_cpu" {
  description = "Elasticsearch CPU limits"
  type        = string
  default     = "500m"
}

variable "es_resources_limits_memory" {
  description = "Elasticsearch memory limits"
  type        = string
  default     = "1Gi"
}

variable "kibana_resources_requests_cpu" {
  description = "Kibana CPU requests"
  type        = string
  default     = "100m"
}

variable "kibana_resources_requests_memory" {
  description = "Kibana memory requests"
  type        = string
  default     = "512Mi"
}

variable "kibana_resources_limits_cpu" {
  description = "Kibana CPU limits"
  type        = string
  default     = "1000m"
}

variable "kibana_resources_limits_memory" {
  description = "Kibana memory limits"
  type        = string
  default     = "1Gi"
}
