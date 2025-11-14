module "upcloud" {
  source = "../../modules/cloud_providers/upcloud"

  partition             = var.partition
  zone                  = var.zone
  k8s_node_plan         = var.k8s_node_plan
  k8s_node_count_min    = var.k8s_node_count_min
  k8s_node_count_max    = var.k8s_node_count_max
  object_storage_region = var.object_storage_region
  object_storage_name   = var.object_storage_name
  autoscaler_username   = var.autoscaler_username
  autoscaler_password   = var.autoscaler_password
  ingress_hostnames = [
    "grafana.${var.cluster_domain}",
    "ozone.${var.cluster_domain}",
    "live2025demo-ozone.${var.cluster_domain}",
    "relay.${var.cluster_domain}",
    "jetstream.${var.cluster_domain}",
    var.pds_hostname,
    "*.${var.pds_hostname}",
    "live2025demo.${var.cluster_domain}",
    "*.live2025demo.${var.cluster_domain}",
  ]
}

module "k8s" {
  source = "../../modules/k8s"

  kubeconfig_host                   = module.upcloud.kubeconfig_host
  kubeconfig_cluster_ca_certificate = module.upcloud.kubeconfig_cluster_ca_certificate
  kubeconfig_client_key             = module.upcloud.kubeconfig_client_key
  kubeconfig_client_certificate     = module.upcloud.kubeconfig_client_certificate

  cloudflare_dns_api_token        = var.cloudflare_dns_api_token
  ingress_nginx_zones             = module.upcloud.zones
  ingress_nginx_extra_annotations = module.upcloud.ingress_nginx_extra_annotations
  maxmind_license_key             = var.maxmind_license_key
  cluster_domain                  = var.cluster_domain
  cert_manager_acme_email         = var.cert_manager_acme_email

  postgres_storage_class        = var.postgres_storage_class
  postgres_backup_s3_access_key = module.upcloud.postgres_backup_s3_access_key
  postgres_backup_s3_secret_key = module.upcloud.postgres_backup_s3_secret_key
  postgres_backup_s3_bucket     = module.upcloud.postgres_backup_s3_bucket
  postgres_backup_s3_region     = module.upcloud.object_storage_region
  postgres_backup_s3_endpoint   = module.upcloud.object_storage_endpoint

  ozone_image           = var.ozone_image
  ozone_appview_url     = var.ozone_appview_url
  ozone_appview_did     = var.ozone_appview_did
  ozone_server_did      = var.ozone_server_did
  ozone_admin_dids      = var.ozone_server_did
  ozone_db_password     = var.ozone_db_password
  ozone_admin_password  = var.ozone_admin_password
  ozone_signing_key_hex = var.ozone_signing_key_hex

  ozone_berlin_db_password     = var.ozone_berlin_db_password
  ozone_berlin_admin_password  = var.ozone_berlin_admin_password
  ozone_berlin_signing_key_hex = var.ozone_berlin_signing_key_hex

  pds_hostname                  = var.pds_hostname
  pds_storage_provisioner       = module.upcloud.storage_provisioner
  pds_storage_size              = var.pds_storage_size
  pds_backup_s3_bucket          = module.upcloud.pds_backup_s3_bucket
  pds_backup_s3_access_key      = module.upcloud.pds_backup_s3_access_key
  pds_backup_s3_secret_key      = module.upcloud.pds_backup_s3_secret_key
  pds_backup_s3_region          = module.upcloud.object_storage_region
  pds_backup_s3_endpoint        = module.upcloud.object_storage_endpoint
  pds_jwt_secret                = var.pds_jwt_secret
  pds_admin_password            = var.pds_admin_password
  pds_plc_rotation_key          = var.pds_plc_rotation_key
  pds_dpop_secret               = var.pds_dpop_secret
  pds_recovery_did_key          = var.pds_recovery_did_key
  pds_blobstore_bucket          = module.upcloud.pds_blobstore_s3_bucket
  pds_blobstore_access_key      = module.upcloud.pds_blobstore_s3_access_key
  pds_blobstore_secret_key      = module.upcloud.pds_blobstore_s3_secret_key
  pds_did_plc_url               = var.pds_did_plc_url
  pds_bsky_app_view_url         = var.pds_bsky_app_view_url
  pds_bsky_app_view_did         = var.pds_bsky_app_view_did
  pds_mod_service_did           = var.ozone_server_did
  pds_blob_upload_limit         = var.pds_blob_upload_limit
  pds_log_enabled               = var.pds_log_enabled
  pds_email_from_address        = var.pds_email_from_address
  pds_email_smtp_url            = var.pds_email_smtp_url
  pds_moderation_email_address  = var.pds_moderation_email_address
  pds_moderation_email_smtp_url = var.pds_moderation_email_smtp_url

  postgres_cluster_name                 = var.postgres_cluster_name
  postgres_recovery_source_cluster_name = var.postgres_recovery_source_cluster_name
  postgres_enable_recovery              = var.postgres_enable_recovery

  prometheus_grafana_admin_password = var.prometheus_grafana_admin_password
  prometheus_storage_class          = var.prometheus_storage_class
  thanos_s3_bucket                  = module.upcloud.metrics_s3_bucket
  thanos_s3_access_key              = module.upcloud.metrics_s3_access_key
  thanos_s3_secret_key              = module.upcloud.metrics_s3_secret_key
  thanos_s3_region                  = module.upcloud.object_storage_region
  thanos_s3_endpoint                = module.upcloud.object_storage_endpoint

  loki_storage_class = var.loki_storage_class
  loki_s3_bucket     = module.upcloud.logs_s3_bucket
  loki_s3_access_key = module.upcloud.logs_s3_access_key
  loki_s3_secret_key = module.upcloud.logs_s3_secret_key
  loki_s3_region     = module.upcloud.object_storage_region
  loki_s3_endpoint   = module.upcloud.object_storage_endpoint

  alert_email        = var.alert_email
  smtp_server        = var.smtp_server
  smtp_port          = var.smtp_port
  smtp_require_tls   = var.smtp_require_tls
  smtp_username      = var.smtp_username
  smtp_password      = var.smtp_password
  deadmansswitch_url = var.deadmansswitch_url

  relay_admin_password       = var.relay_admin_password
  relay_storage_class        = var.relay_storage_class
  relay_storage_size         = var.relay_storage_size
  relay_backup_s3_bucket     = module.upcloud.relay_backup_s3_bucket
  relay_backup_s3_access_key = module.upcloud.relay_backup_s3_access_key
  relay_backup_s3_secret_key = module.upcloud.relay_backup_s3_secret_key
  relay_backup_s3_region     = module.upcloud.object_storage_region
  relay_backup_s3_endpoint   = module.upcloud.object_storage_endpoint

  pds_berlin_jwt_secret            = var.pds_berlin_jwt_secret
  pds_berlin_admin_password        = var.pds_berlin_admin_password
  pds_berlin_plc_rotation_key      = var.pds_berlin_plc_rotation_key
  pds_berlin_dpop_secret           = var.pds_berlin_dpop_secret
  pds_berlin_recovery_did_key      = var.pds_berlin_recovery_did_key
  pds_berlin_blobstore_bucket      = module.upcloud.pds_berlin_blobstore_s3_bucket
  pds_berlin_blobstore_access_key  = module.upcloud.pds_berlin_blobstore_s3_access_key
  pds_berlin_blobstore_secret_key  = module.upcloud.pds_berlin_blobstore_s3_secret_key
  pds_berlin_backup_s3_bucket      = module.upcloud.pds_berlin_backup_s3_bucket
  pds_berlin_backup_s3_access_key  = module.upcloud.pds_berlin_backup_s3_access_key
  pds_berlin_backup_s3_secret_key  = module.upcloud.pds_berlin_backup_s3_secret_key
  pds_berlin_backup_s3_region      = module.upcloud.object_storage_region
  pds_berlin_backup_s3_endpoint    = module.upcloud.object_storage_endpoint
}
