variable "enabled" {
  description = "Whether to deploy the PLC service."
  type        = bool
  default     = true
}

variable "partition" {
  description = "The partition for the current environment (e.g., 'local', 'dev', 'prod')."
  type        = string
}

variable "domain" {
  description = "The domain for the cluster."
  type        = string
}

variable "image_name" {
  description = "The name of the PLC Docker image."
  type        = string
  default     = "ghcr.io/eurosky-social/did-method-plc"
}

variable "image_tag" {
  description = "The tag of the PLC Docker image."
  type        = string
  default     = "latest"
}

variable "replicas" {
  description = "The number of replicas for the PLC deployment."
  type        = number
  default     = 1
}

variable "postgres_cluster_name" {
  description = "The name of the PostgreSQL cluster."
  type        = string
}

variable "postgres_namespace" {
  description = "The namespace where the PostgreSQL cluster is deployed."
  type        = string
}

variable "plc_db_password" {
  description = "The password for the PLC database user."
  type        = string
}