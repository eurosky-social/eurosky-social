# TODO: Add SigNoz for distributed tracing and APM
# TODO: Hubble (Cilium observability) for network flow visibility and egress monitoring
# TODO: Implement lateral movement protection
# TODO: Switch to GitOps workflow (e.g., ArgoCD or Flux) for declarative, automated deployment and configuration management
# TODO: separate topology per workloads (dedicated nodes per core, apps, o11y, noisy apps, etc)
# TODO: refactor module by workloads (e.g. monitoring for prometheus, loki)

module "prometheus_stack" {
  source = "./prometheus-stack"

  grafana_admin_password = var.prometheus_grafana_admin_password
  storage_class          = var.prometheus_storage_class
  cluster_domain         = var.cluster_domain
  alert_email            = var.alert_email
  smtp_server            = var.smtp_server
  smtp_port              = var.smtp_port
  smtp_require_tls       = var.smtp_require_tls
  smtp_username          = var.smtp_username
  smtp_password          = var.smtp_password
  deadmansswitch_url     = var.deadmansswitch_url
  thanos_s3_bucket       = var.thanos_s3_bucket
  thanos_s3_region       = var.thanos_s3_region
  thanos_s3_endpoint     = var.thanos_s3_endpoint
  thanos_s3_access_key   = var.thanos_s3_access_key
  thanos_s3_secret_key   = var.thanos_s3_secret_key
}

module "cert_manager" {
  source = "./cert-manager"

  cloudflare_dns_api_token = var.cloudflare_dns_api_token
  acme_email               = var.cert_manager_acme_email

  depends_on = [module.prometheus_stack]
}

module "ingress_nginx" {
  source = "./ingress-nginx"

  zones               = var.ingress_nginx_zones
  cluster_domain      = var.cluster_domain
  extra_annotations   = var.ingress_nginx_extra_annotations
  maxmind_license_key = var.maxmind_license_key

  depends_on = [module.prometheus_stack]
}

module "external_dns" {
  source = "./external-dns"

  api_token      = var.cloudflare_dns_api_token
  cluster_domain = var.cluster_domain

  depends_on = [module.ingress_nginx]
}

module "postgres" {
  source = "./postgres"

  storage_class                = var.postgres_storage_class
  backup_s3_access_key         = var.postgres_backup_s3_access_key
  backup_s3_secret_key         = var.postgres_backup_s3_secret_key
  backup_s3_bucket             = var.postgres_backup_s3_bucket
  backup_s3_region             = var.postgres_backup_s3_region
  backup_s3_endpoint           = var.postgres_backup_s3_endpoint
  ozone_db_password            = var.ozone_db_password
  postgres_cluster_name        = var.postgres_cluster_name
  recovery_source_cluster_name = var.postgres_recovery_source_cluster_name
  enable_recovery              = var.postgres_enable_recovery

  depends_on = [module.cert_manager]
}

module "ozone" {
  source = "./ozone"

  cluster_domain          = var.cluster_domain
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
  pds_hostname            = var.pds_hostname

  depends_on = [module.postgres, module.ingress_nginx]
}

module "pds" {
  source = "./pds"

  cluster_domain                = var.cluster_domain
  pds_hostname                  = var.pds_hostname
  storage_provisioner           = var.pds_storage_provisioner
  pds_storage_size              = var.pds_storage_size
  backup_bucket                 = var.pds_backup_s3_bucket
  backup_region                 = var.pds_backup_s3_region
  backup_endpoint               = var.pds_backup_s3_endpoint
  backup_access_key             = var.pds_backup_s3_access_key
  backup_secret_key             = var.pds_backup_s3_secret_key
  pds_jwt_secret                = var.pds_jwt_secret
  pds_admin_password            = var.pds_admin_password
  pds_plc_rotation_key          = var.pds_plc_rotation_key
  pds_dpop_secret               = var.pds_dpop_secret
  pds_recovery_did_key          = var.pds_recovery_did_key
  pds_blobstore_bucket          = var.pds_blobstore_bucket
  pds_blobstore_access_key      = var.pds_blobstore_access_key
  pds_blobstore_secret_key      = var.pds_blobstore_secret_key
  pds_did_plc_url               = var.pds_did_plc_url
  pds_bsky_app_view_url         = var.pds_bsky_app_view_url
  pds_bsky_app_view_did         = var.pds_bsky_app_view_did
  pds_mod_service_url           = module.ozone.public_url
  pds_mod_service_did           = var.pds_mod_service_did
  pds_blob_upload_limit         = var.pds_blob_upload_limit
  pds_log_enabled               = var.pds_log_enabled
  pds_email_from_address        = var.pds_email_from_address
  pds_email_smtp_url            = var.pds_email_smtp_url
  pds_moderation_email_address  = var.pds_moderation_email_address
  pds_moderation_email_smtp_url = var.pds_moderation_email_smtp_url

  depends_on = [module.ingress_nginx]
}

module "loki" {
  source = "./loki"

  storage_class        = var.loki_storage_class
  s3_bucket            = var.loki_s3_bucket
  s3_region            = var.loki_s3_region
  s3_endpoint          = var.loki_s3_endpoint
  s3_access_key        = var.loki_s3_access_key
  s3_secret_key        = var.loki_s3_secret_key
  monitoring_namespace = module.prometheus_stack.monitoring_namespace

  depends_on = [module.prometheus_stack]
}

module "relay" {
  source = "./relay"

  relay_admin_password = var.relay_admin_password
  relay_storage_class  = var.relay_storage_class
  relay_storage_size   = var.relay_storage_size
  cluster_domain       = var.cluster_domain
  backup_bucket        = var.relay_backup_s3_bucket
  backup_region        = var.relay_backup_s3_region
  backup_endpoint      = var.relay_backup_s3_endpoint
  backup_access_key    = var.relay_backup_s3_access_key
  backup_secret_key    = var.relay_backup_s3_secret_key

  depends_on = [module.ingress_nginx]
}

module "ozone_berlin" {
  source = "./ozone-berlin"

  cluster_domain               = var.cluster_domain
  ozone_berlin_db_password     = var.ozone_berlin_db_password
  ozone_berlin_admin_password  = var.ozone_berlin_admin_password
  ozone_berlin_signing_key_hex = var.ozone_berlin_signing_key_hex
  postgres_namespace           = module.postgres.namespace
  postgres_cluster_name        = module.postgres.cluster_name
  postgres_ca_secret_name      = module.postgres.ca_secret_name

  depends_on = [module.postgres, module.ingress_nginx]
}

module "pds_berlin" {
  source = "./pds-berlin"

  cluster_domain                = var.cluster_domain
  storage_provisioner           = var.pds_storage_provisioner
  backup_bucket                 = var.pds_berlin_backup_s3_bucket
  backup_region                 = var.pds_berlin_backup_s3_region
  backup_endpoint               = var.pds_berlin_backup_s3_endpoint
  backup_access_key             = var.pds_berlin_backup_s3_access_key
  backup_secret_key             = var.pds_berlin_backup_s3_secret_key
  pds_jwt_secret                = var.pds_berlin_jwt_secret
  pds_admin_password            = var.pds_berlin_admin_password
  pds_plc_rotation_key          = var.pds_berlin_plc_rotation_key
  pds_dpop_secret               = var.pds_berlin_dpop_secret
  pds_recovery_did_key          = var.pds_berlin_recovery_did_key
  pds_blobstore_bucket          = var.pds_berlin_blobstore_bucket
  pds_blobstore_access_key      = var.pds_berlin_blobstore_access_key
  pds_blobstore_secret_key      = var.pds_berlin_blobstore_secret_key
  pds_email_from_address        = var.pds_email_from_address
  pds_email_smtp_url            = var.pds_email_smtp_url
  pds_moderation_email_address  = var.pds_moderation_email_address
  pds_moderation_email_smtp_url = var.pds_moderation_email_smtp_url

  depends_on = [module.ingress_nginx]
}

module "hepa" {
  source = "./hepa"

  cluster_domain       = var.cluster_domain
  ozone_did            = "did:plc:m4jxet5jry3f5xjxxedu6mt3"
  ozone_admin_password = var.ozone_berlin_admin_password
  pds_admin_password   = var.pds_berlin_admin_password

  depends_on = [module.pds_berlin, module.ozone_berlin]
}

module "jetstream" {
  source = "./jetstream"

  cluster_domain = var.cluster_domain

  depends_on = [module.relay, module.ingress_nginx]
}
