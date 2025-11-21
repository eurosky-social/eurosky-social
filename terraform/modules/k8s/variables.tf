# Kubeconfig variables (optional - if not provided, will use kubeconfig file)
variable "kubeconfig_path" {
  description = "Path to kubeconfig file (use when kubeconfig_host is empty)"
  type        = string
  default     = "~/.kube/config"
}

variable "kubeconfig_host" {
  description = "Kubernetes API server host (leave empty to use kubeconfig file)"
  type        = string
  default     = ""
}

variable "kubeconfig_token" {
  description = "Kubernetes API token (leave empty to use kubeconfig file)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "kubeconfig_client_certificate" {
  description = "Base64-encoded client certificate (leave empty to use kubeconfig file)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "kubeconfig_client_key" {
  description = "Base64-encoded client key (leave empty to use kubeconfig file)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "kubeconfig_cluster_ca_certificate" {
  description = "Base64-encoded cluster CA certificate (leave empty to use kubeconfig file)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "external_dns_secrets" {
  description = "Cloud provider secrets for external-dns (map of env var names to secret values)"
  type        = map(string)
  sensitive   = true
}

variable "external_dns_provider" {
  description = "Cloud provider name for external-dns (scaleway, cloudflare, etc.)"
  type        = string
}

variable "extra_nginx_annotations" {
  description = "Extra annotations for ingress-nginx LoadBalancer (cloud provider specific or DNS overrides)"
  type        = map(string)
  default     = {}
}

variable "maxmind_license_key" {
  description = "MaxMind license key for GeoIP2 database (get free key at https://www.maxmind.com/en/geolite2/signup)"
  type        = string
  sensitive   = true
  default     = ""
}

variable "cert_manager_secrets" {
  description = "DNS provider secrets for cert-manager (map of key names to secret values)"
  type        = map(string)
  sensitive   = true
}

variable "cert_manager_secret_name" {
  description = "Name for the cert-manager DNS credentials secret"
  type        = string
}

variable "cert_manager_solver_config" {
  description = "DNS01 solver configuration (YAML string) - provider-specific, defined by caller"
  type        = string
}

variable "ingress_nginx_zones" {
  description = "List of zones for load balancer deployment"
  type        = list(string)
}

variable "cluster_domain" {
  description = "Full cluster domain (subdomain.domain)"
  type        = string
}

variable "cert_manager_acme_email" {
  description = "Email for ACME registration"
  type        = string
}

variable "ozone_cert_manager_issuer" {
  description = "cert-manager ClusterIssuer for Ozone ingress"
  type        = string
}

variable "pds_cert_manager_issuer" {
  description = "cert-manager ClusterIssuer for PDS ingress"
  type        = string
}

variable "kibana_cert_manager_issuer" {
  description = "cert-manager ClusterIssuer for Kibana ingress"
  type        = string
}

variable "elasticsearch_storage_class" {
  description = "Storage class for Elasticsearch persistent volumes"
  type        = string
}

variable "postgres_storage_class" {
  description = "Storage class for PostgreSQL persistent volumes"
  type        = string
}

variable "backup_s3_access_key" {
  description = "S3 access key for all backups (PostgreSQL, Litestream)"
  type        = string
  sensitive   = true
}

variable "backup_s3_secret_key" {
  description = "S3 secret key for all backups (PostgreSQL, Litestream)"
  type        = string
  sensitive   = true
}

variable "backup_s3_bucket" {
  description = "S3 bucket for all backups (postgres/, litestream/ prefixes)"
  type        = string
}

variable "backup_s3_region" {
  description = "S3 region for backup bucket"
  type        = string
}

variable "backup_s3_endpoint" {
  description = "S3 endpoint URL for backup bucket"
  type        = string
}

variable "ozone_image" {
  description = "Docker image for Ozone"
  type        = string
}

variable "ozone_public_hostname" {
  description = "Public hostname for Ozone (optional, defaults to ozone.<cluster_domain>)"
  type        = string
  default     = null
}

variable "ozone_appview_url" {
  description = "Appview URL for Ozone"
  type        = string
}

variable "ozone_appview_did" {
  description = "Appview DID for Ozone"
  type        = string
}

variable "ozone_server_did" {
  description = "Server DID for Ozone (e.g., did:plc:... or did:web:...)"
  type        = string
}

variable "ozone_admin_dids" {
  description = "Admin DIDs for Ozone (comma-separated)"
  type        = string
}

variable "ozone_db_password" {
  description = "The password for the Ozone database user."
  type        = string
}

variable "plc_db_password" {
  description = "The password for the PLC database user."
  type        = string
}

variable "ozone_admin_password" {
  description = "Admin password for Ozone"
  type        = string
  sensitive   = true
}

variable "ozone_signing_key_hex" {
  description = "Signing key (hex) for Ozone"
  type        = string
  sensitive   = true
}

variable "pds_storage_provisioner" {
  description = "Storage provisioner for PDS volumes"
  type        = string
}

variable "pds_storage_size" {
  description = "PDS storage size"
  type        = string
}

variable "pds_jwt_secret" {
  description = "JWT secret for PDS authentication"
  type        = string
  sensitive   = true
}

variable "pds_admin_password" {
  description = "Admin password for PDS"
  type        = string
  sensitive   = true
}

variable "pds_plc_rotation_key" {
  description = "PLC rotation key (K256 private key hex)"
  type        = string
  sensitive   = true
}

variable "pds_blobstore_bucket" {
  description = "S3 bucket for PDS blob storage"
  type        = string
}

variable "pds_blobstore_access_key" {
  description = "S3 access key for PDS blobstore"
  type        = string
  sensitive   = true
}

variable "pds_blobstore_secret_key" {
  description = "S3 secret key for PDS blobstore"
  type        = string
  sensitive   = true
}

variable "pds_did_plc_url" {
  description = "PLC directory URL for DID resolution"
  type        = string
  default     = "https://plc.directory"
}

variable "pds_bsky_app_view_url" {
  description = "Bluesky App View URL"
  type        = string
  default     = "https://api.bsky.app"
}

variable "pds_bsky_app_view_did" {
  description = "Bluesky App View DID"
  type        = string
  default     = "did:web:api.bsky.app"
}

variable "pds_report_service_url" {
  description = "Moderation/reporting service URL (Ozone)"
  type        = string
  default     = "https://mod.bsky.app"
}

variable "pds_report_service_did" {
  description = "Moderation/reporting service DID (Ozone)"
  type        = string
  default     = "did:plc:ar7c4by46qjdydhdevvrndac"
}

variable "pds_blob_upload_limit" {
  description = "Maximum blob upload size in bytes"
  type        = string
  default     = "52428800"
}

variable "pds_log_enabled" {
  description = "Enable logging"
  type        = string
  default     = "true"
}

variable "pds_email_from_address" {
  description = "Email from address for PDS notifications"
  type        = string
  default     = ""
}

variable "pds_email_smtp_url" {
  description = "SMTP URL for email sending (format: smtps://user:pass@host:port/)"
  type        = string
  sensitive   = true
  default     = ""
}

variable "pds_public_hostname" {
  description = "Public hostname for PDS (optional, defaults to pds.<cluster_domain>)"
  type        = string
  default     = null
}

variable "pds_enabled" {
  description = "Whether to deploy the PDS service."
  type        = bool
  default     = true
}

variable "pds_moderation_email_smtp_url" {
  description = "SMTP URL for moderation email sending."
  type        = string
  default     = ""
}

variable "pds_moderation_email_address" {
  description = "Moderation email address."
  type        = string
  default     = ""
}

variable "pds_mod_service_url" {
  description = "Moderation service URL (Ozone)."
  type        = string
}

variable "pds_mod_service_did" {
  description = "Moderation service DID (Ozone)."
  type        = string
}

variable "pds_port" {
  description = "PDS service port."
  type        = number
  default     = 3000
}

variable "pds_recovery_did_key" {
  description = "PDS recovery DID key."
  type        = string
}

variable "pds_disable_ssrf_protection" {
  description = "Disable SSRF protection for PDS."
  type        = bool
  default     = true
}

variable "pds_dev_mode" {
  description = "Enable PDS development mode."
  type        = bool
  default     = true
}

variable "pds_invite_required" {
  description = "Require invite code for PDS."
  type        = bool
  default     = false
}

variable "pds_image_name" {
  description = "The name of the PDS Docker image."
  type        = string
  default     = "ghcr.io/bluesky-social/pds"
}

variable "pds_image_tag" {
  description = "The tag of the PDS Docker image."
  type        = string
  default     = "latest"
}

variable "pds_replicas" {
  description = "The number of replicas for the PDS deployment."
  type        = number
  default     = 1
}

variable "pds_partition" {
  description = "The partition for the current environment (e.g., 'local', 'dev', 'prod')."
  type        = string
}


variable "pds_log_level" {
  description = "Log level for PDS."
  type        = string
  default     = "debug"
}

variable "postgres_instances" {
  description = "Number of PostgreSQL instances (1 for local/dev, 3+ for production HA)"
  type        = number
  default     = 1
}

variable "postgres_storage_size" {
  description = "PostgreSQL storage size"
  type        = string
  default     = "1Gi"
}

variable "postgres_cluster_name" {
  description = "PostgreSQL cluster name (increment version for recovery: postgres-cluster-v2, v3, etc.)"
  type        = string
  default     = "postgres-cluster"
}

variable "postgres_recovery_source_cluster_name" {
  description = "Source cluster name to recover FROM (usually the original: postgres-cluster)"
  type        = string
  default     = "postgres-cluster-old"
}

variable "postgres_enable_recovery" {
  description = "Enable recovery from S3 backup instead of fresh initdb (false for first deployment, true for disaster recovery)"
  type        = bool
  default     = false
}

variable "prometheus_grafana_admin_password" {
  description = "Grafana admin password for Prometheus stack"
  type        = string
  sensitive   = true
}

variable "prometheus_storage_class" {
  description = "Storage class for Prometheus stack persistent volumes"
  type        = string
}
