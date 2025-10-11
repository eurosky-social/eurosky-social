variable "namespace_id" {
  description = "The Scaleway container namespace ID"
  type        = string
}

variable "hostname" {
  description = "The domain name for Ozone service"
  type        = string
}

variable "registry_image" {
  description = "The Docker registry image for Ozone"
  type        = string
  default     = "ghcr.io/eurosky-social/ozone:latest"
}

variable "database_name" {
  description = "The name of the PostgreSQL database"
  type        = string
  default     = "ozone"
}

variable "min_cpu_limit" {
  description = "Minimum CPU limit for the database"
  type        = number
  default     = 0
}

variable "max_cpu_limit" {
  description = "Maximum CPU limit for the database"
  type        = number
  default     = 1
}

variable "port" {
  description = "Container port"
  type        = number
  default     = 3000
}

variable "cpu_limit" {
  description = "CPU limit in mCPU (1000 = 1 vCPU)"
  type        = number
  default     = 250
}

variable "memory_limit" {
  description = "Memory limit in MB"
  type        = number
  default     = 256
}

variable "min_scale" {
  description = "Minimum number of container instances"
  type        = number
  default     = 0
}

variable "max_scale" {
  description = "Maximum number of container instances"
  type        = number
  default     = 1
}

variable "node_env" {
  description = "Node environment"
  type        = string
  default     = "production"
}

variable "log_enabled" {
  description = "Enable logging"
  type        = string
  default     = "true"
}

variable "log_level" {
  description = "Log level"
  type        = string
  default     = "info"
}

variable "ozone_db_migrate" {
  description = "Enable database migrations"
  type        = string
  default     = "0"
}

variable "environment_variables" {
  description = "Environment variables for the Ozone container"
  type        = map(string)
  default     = {}
}

variable "secret_environment_variables" {
  description = "Secret environment variables for the Ozone container"
  type        = map(string)
  sensitive   = true
  default     = {}
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = list(string)
  default     = ["ozone"]
}

variable "ozone_did_plc_url" {
  description = "PLC directory URL for DID resolution"
  type        = string
}

variable "ozone_appview_url" {
  description = "AppView URL for Bluesky integration"
  type        = string
}

variable "ozone_appview_did" {
  description = "AppView DID for Bluesky integration"
  type        = string
}

variable "plc_directory_url" {
  description = "PLC directory URL"
  type        = string
}

variable "handle_resolver_url" {
  description = "Handle resolver URL"
  type        = string
}

variable "ozone_admin_password" {
  description = "Admin password for Ozone"
  type        = string
  sensitive   = true
}

variable "ozone_signing_key_hex" {
  description = "Signing key in hex format for Ozone"
  type        = string
  sensitive   = true
}

variable "ozone_server_did" {
  description = "DID for the Ozone server (required)"
  type        = string
}

variable "ozone_admin_dids" {
  description = "Comma-separated list of admin DIDs"
  type        = string
  default     = ""
}
