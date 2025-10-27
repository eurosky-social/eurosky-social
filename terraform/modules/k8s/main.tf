# TODO: Improve observability (o11y) - consider integrating:
#   - SigNoz for distributed tracing and APM
#   - Alerting infrastructure for proactive monitoring
#
# TODO: Switch to GitOps workflow (e.g., ArgoCD or Flux) for declarative,
#   automated deployment and configuration management

# TODO: separate topology per workloads (dedicated nodes per core, apps, o11y, noisy apps, etc)

module "cert_manager" {
  source = "./cert-manager"

  dns_secrets   = var.cert_manager_secrets
  secret_name   = var.cert_manager_secret_name
  solver_config = var.cert_manager_solver_config
  acme_email    = var.cert_manager_acme_email
}

module "ingress_nginx" {
  source = "./ingress-nginx"

  zones                   = var.ingress_nginx_zones
  cluster_domain          = var.cluster_domain
  extra_nginx_annotations = var.extra_nginx_annotations

  depends_on = [module.cert_manager]
}

module "external_dns" {
  source = "./external-dns"

  keys           = var.external_dns_secrets
  cluster_domain = var.cluster_domain
  dns_provider   = var.external_dns_provider

  depends_on = [module.ingress_nginx]
}

# module "elastic" {
#   source = "./elastic"

#   storage_class       = var.elasticsearch_storage_class
#   cluster_domain      = var.cluster_domain
#   cert_manager_issuer = var.kibana_cert_manager_issuer

#   depends_on = [module.cert_manager, module.ingress_nginx]
# }

module "postgres" {
  source = "./postgres"

  storage_class                = var.postgres_storage_class
  backup_s3_access_key         = var.backup_s3_access_key

  backup_s3_bucket             = var.backup_s3_bucket
  backup_s3_region             = var.backup_s3_region
  backup_s3_endpoint           = var.backup_s3_endpoint
  backup_s3_secret_key         = var.backup_s3_secret_key

  ozone_db_password            = var.ozone_db_password
  plc_db_password              = var.plc_db_password
  postgres_instances           = var.postgres_instances
  postgres_storage_size        = var.postgres_storage_size
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
  count = var.pds_enabled ? 1 : 0
  source = "./pds"

  enabled = var.pds_enabled
  partition = var.pds_partition
  domain = var.cluster_domain
  image_name = var.pds_image_name
  image_tag = var.pds_image_tag
  replicas = var.pds_replicas

  pds_admin_password = var.pds_admin_password
  pds_blobstore_disk_location = var.pds_blobstore_disk_location
  pds_data_directory = var.pds_data_directory
  pds_did_plc_url = var.pds_did_plc_url
  pds_hostname = var.pds_public_hostname
  pds_jwt_secret = var.pds_jwt_secret
  pds_port = var.pds_port
  pds_plc_rotation_key_k256_private_key_hex = var.pds_plc_rotation_key
  pds_recovery_did_key = var.pds_recovery_did_key
  pds_disable_ssrf_protection = var.pds_disable_ssrf_protection
  pds_dev_mode = var.pds_dev_mode
  pds_invite_required = var.pds_invite_required
  pds_bsky_app_view_url = var.pds_bsky_app_view_url
  pds_bsky_app_view_did = var.pds_bsky_app_view_did
  pds_email_smtp_url = var.pds_email_smtp_url
  pds_email_from_address = var.pds_email_from_address
  pds_moderation_email_smtp_url = var.pds_moderation_email_smtp_url
  pds_moderation_email_address = var.pds_moderation_email_address
  pds_mod_service_url = var.pds_mod_service_url
  pds_mod_service_did = var.pds_mod_service_did
  log_enabled = var.pds_log_enabled
  log_level = var.pds_log_level

  depends_on = [module.ingress_nginx]
}

module "prometheus_stack" {
  source = "./prometheus-stack"

  grafana_admin_password = var.prometheus_grafana_admin_password
  storage_class          = var.prometheus_storage_class

  depends_on = [module.cert_manager, module.ingress_nginx]
}
