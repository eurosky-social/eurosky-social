# TODO: Improve observability (o11y) - consider integrating:
#   - SigNoz for distributed tracing and APM
#   - Alerting infrastructure for proactive monitoring
#   - Hubble (Cilium observability) for network flow visibility and egress monitoring
#
# TODO: Implement lateral movement protection
#
# TODO: Switch to GitOps workflow (e.g., ArgoCD or Flux) for declarative,
#   automated deployment and configuration management

# TODO: separate topology per workloads (dedicated nodes per core, apps, o11y, noisy apps, etc)

# TODO: Consider explicitly managing metrics-server via Helm instead of relying on platform defaults

# TODO: refactor module by workloads (e.g. monitoring for prometheus, loki)

module "prometheus_stack" {
  source = "./prometheus-stack"

  grafana_admin_password = var.prometheus_grafana_admin_password
  storage_class          = var.prometheus_storage_class
  cluster_domain         = var.cluster_domain
  alert_email            = var.alert_email
}

module "cert_manager" {
  source = "./cert-manager"

  scw_access_key        = var.external_dns_access_key
  scw_secret_key        = var.external_dns_secret_key
  acme_email            = var.cert_manager_acme_email
}

module "ingress_nginx" {
  source = "./ingress-nginx"

  zones                = var.ingress_nginx_zones
  cluster_domain       = var.cluster_domain
  cloud_provider       = "scaleway"

  depends_on = [module.cert_manager, module.prometheus_stack]
}

module "external_dns" {
  source = "./external-dns"

  access_key     = var.external_dns_access_key
  secret_key     = var.external_dns_secret_key
  cluster_domain = var.cluster_domain
  cloud_provider = "scaleway"

  depends_on = [module.ingress_nginx]
}

module "postgres" {
  source = "./postgres"

  storage_class                = var.postgres_storage_class
  backup_s3_access_key         = var.backup_s3_access_key
  backup_s3_secret_key         = var.backup_s3_secret_key
  backup_s3_bucket             = var.backup_s3_bucket
  backup_s3_region             = var.backup_s3_region
  backup_s3_endpoint           = var.backup_s3_endpoint
  ozone_db_password            = var.ozone_db_password
  postgres_cluster_name        = var.postgres_cluster_name
  recovery_source_cluster_name = var.postgres_recovery_source_cluster_name
  enable_recovery              = var.postgres_enable_recovery

  depends_on = [module.cert_manager]
}

module "ozone" {
  source = "./ozone"

  cluster_domain          = var.cluster_domain
  cert_manager_issuer     = var.ozone_cert_manager_issuer
  ozone_public_hostname   = var.ozone_public_hostname
  ozone_image             = var.ozone_image
  ozone_appview_url       = var.ozone_appview_url
  ozone_appview_did       = var.ozone_appview_did
  ozone_server_did        = var.ozone_server_did
  ozone_admin_dids        = var.ozone_admin_dids
  ozone_db_password       = var.ozone_db_password
  ozone_admin_password    = var.ozone_admin_password
  ozone_signing_key_hex   = var.ozone_signing_key_hex
  postgres_namespace      = module.postgres.namespace
  postgres_cluster_name   = module.postgres.cluster_name
  postgres_ca_secret_name = module.postgres.ca_secret_name
  postgres_pooler_name    = module.postgres.pooler_name

  depends_on = [module.postgres, module.ingress_nginx]
}

module "pds" {
  source = "./pds"

  cluster_domain           = var.cluster_domain
  cert_manager_issuer      = var.pds_cert_manager_issuer
  storage_provisioner      = var.pds_storage_provisioner
  pds_storage_size         = var.pds_storage_size
  backup_bucket            = var.backup_s3_bucket
  backup_region            = var.backup_s3_region
  backup_endpoint          = var.backup_s3_endpoint
  backup_access_key        = var.backup_s3_access_key
  backup_secret_key        = var.backup_s3_secret_key
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

  depends_on = [module.ingress_nginx]
}

module "loki" {
  source = "./loki"

  storage_class        = var.loki_storage_class
  s3_bucket            = var.backup_s3_bucket
  s3_region            = var.backup_s3_region
  s3_endpoint          = var.backup_s3_endpoint
  s3_access_key        = var.backup_s3_access_key
  s3_secret_key        = var.backup_s3_secret_key
  monitoring_namespace = module.prometheus_stack.monitoring_namespace

  depends_on = [module.prometheus_stack]
}
