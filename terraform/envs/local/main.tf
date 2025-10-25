# Local k3d Environment Configuration

# TODO: Implement certificate backup strategy to avoid Let's Encrypt rate limits
module "k8s" {
  source = "../../modules/k8s"

  # External DNS configuration
  external_dns_provider = "cloudflare"
  external_dns_secrets = {
    CF_API_TOKEN = var.cloudflare_api_token
    CF_API_EMAIL = var.cloudflare_email
  }

  extra_nginx_annotations = {
    "external-dns.alpha.kubernetes.io/target" = "127.0.0.1"
  }

  cert_manager_secret_name = "cloudflare-api-token"
  cert_manager_secrets = {
    api-token = var.cloudflare_api_token
  }
  cert_manager_solver_config = <<YAML
    - dns01:
        cloudflare:
          apiTokenSecretRef:
            name: cloudflare-api-token
            key: api-token
YAML

  # Ingress and domain configuration
  ingress_nginx_zones     = var.zones
  cluster_domain          = var.cluster_domain
  cert_manager_acme_email = var.cert_manager_acme_email

  # Certificate issuers (use letsencrypt-staging for local to avoid rate limits)
  ozone_cert_manager_issuer  = var.ozone_cert_manager_issuer
  pds_cert_manager_issuer    = var.pds_cert_manager_issuer
  kibana_cert_manager_issuer = var.kibana_cert_manager_issuer

  # Ozone configuration
  ozone_public_hostname = var.ozone_public_hostname
  ozone_image           = var.ozone_image
  ozone_appview_url     = var.ozone_appview_url
  ozone_appview_did     = var.ozone_appview_did
  ozone_server_did      = var.ozone_server_did
  ozone_admin_dids      = var.ozone_admin_dids
  ozone_db_password     = var.ozone_db_password
  ozone_admin_password  = var.ozone_admin_password
  ozone_signing_key_hex = var.ozone_signing_key_hex

  # Storage configuration - k3d uses local-path provisioner
  elasticsearch_storage_class = var.elasticsearch_storage_class
  postgres_storage_class      = var.postgres_storage_class

  # Backup configuration - linked to local MinIO resource
  backup_s3_access_key = local.minio_root_user
  backup_s3_secret_key = local.minio_root_password
  backup_s3_bucket     = local.minio_bucket_backups
  backup_s3_region     = local.minio_region
  backup_s3_endpoint   = "http://${data.external.machine_ip.result.ip}:${local.minio_api_port}"

  # PDS configuration
  pds_storage_provisioner  = var.pds_storage_provisioner  # rancher.io/local-path for k3d
  pds_storage_size         = var.pds_storage_size
  pds_jwt_secret           = var.pds_jwt_secret
  pds_admin_password       = var.pds_admin_password
  pds_plc_rotation_key     = var.pds_plc_rotation_key
  pds_blobstore_bucket     = var.pds_blobstore_bucket
  pds_blobstore_access_key = var.pds_blobstore_access_key
  pds_blobstore_secret_key = var.pds_blobstore_secret_key
  pds_did_plc_url          = var.pds_did_plc_url
  pds_bsky_app_view_url    = var.pds_bsky_app_view_url
  pds_bsky_app_view_did    = var.pds_bsky_app_view_did
  pds_report_service_url   = var.pds_report_service_url
  pds_report_service_did   = var.pds_report_service_did
  pds_blob_upload_limit    = var.pds_blob_upload_limit
  pds_log_enabled          = var.pds_log_enabled
  pds_email_from_address   = var.pds_email_from_address
  pds_email_smtp_url       = var.pds_email_smtp_url
  pds_public_hostname      = var.pds_public_hostname

  # PostgreSQL configuration for local development
  postgres_instances    = 1
  postgres_storage_size = "5Gi"

  # Prometheus configuration
  prometheus_grafana_admin_password = var.prometheus_grafana_admin_password
  prometheus_storage_class          = var.prometheus_storage_class
}

# Get machine IP for k8s cluster access
data "external" "machine_ip" {
  program = ["sh", "-c", "echo '{\"ip\": \"'$(ifconfig | grep 'inet ' | grep -v '127.0.0.1' | head -1 | awk '{print $2}')'\"}'"]
}

