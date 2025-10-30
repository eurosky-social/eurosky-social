module "upcloud" {
  source = "../../modules/cloud_providers/upcloud"

  project                   = var.project
  zone                      = var.zone
  k8s_node_plan             = var.k8s_node_plan
  k8s_node_min_count        = var.k8s_node_min_count
  k8s_node_max_count        = var.k8s_node_max_count
  backup_bucket_name        = var.backup_bucket_name
  pds_blobstore_bucket_name = var.pds_blobstore_bucket_name
  object_storage_region     = var.object_storage_region
  object_storage_name       = var.object_storage_name
}

module "k8s" {
  source = "../../modules/k8s"

  kubeconfig_host = module.upcloud.kubeconfig_host
  kubeconfig_cluster_ca_certificate = module.upcloud.kubeconfig_cluster_ca_certificate
  kubeconfig_client_key = module.upcloud.kubeconfig_client_key
  kubeconfig_client_certificate = module.upcloud.kubeconfig_client_certificate

  cluster_domain = var.cluster_domain
  ingress_nginx_zones = module.upcloud.zones
  cert_manager_acme_email = var.cert_manager_acme_email

  ozone_cert_manager_issuer  = var.ozone_cert_manager_issuer
  pds_cert_manager_issuer    = var.pds_cert_manager_issuer

  ozone_public_hostname = var.ozone_public_hostname

  postgres_storage_class = var.postgres_storage_class
  backup_s3_access_key = module.upcloud.backup_s3_access_key
  backup_s3_secret_key = module.upcloud.backup_s3_secret_key
  backup_s3_bucket     = module.upcloud.backup_s3_bucket
  backup_s3_region     = module.upcloud.backup_s3_region
  backup_s3_endpoint   = module.upcloud.backup_s3_endpoint

  ozone_image           = var.ozone_image
  ozone_appview_url     = var.ozone_appview_url
  ozone_appview_did     = var.ozone_appview_did
  ozone_server_did      = var.ozone_server_did
  ozone_admin_dids      = var.ozone_admin_dids
  ozone_db_password     = var.ozone_db_password
  ozone_admin_password  = var.ozone_admin_password
  ozone_signing_key_hex = var.ozone_signing_key_hex

  pds_storage_provisioner  = module.upcloud.storage_provisioner
  pds_storage_size         = var.pds_storage_size
  pds_jwt_secret           = var.pds_jwt_secret
  pds_admin_password       = var.pds_admin_password
  pds_plc_rotation_key     = var.pds_plc_rotation_key
  pds_blobstore_bucket     = module.upcloud.pds_blobstore_bucket
  pds_blobstore_access_key = module.upcloud.pds_blobstore_access_key
  pds_blobstore_secret_key = module.upcloud.pds_blobstore_secret_key
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

  postgres_cluster_name                 = var.postgres_cluster_name
  postgres_recovery_source_cluster_name = var.postgres_recovery_source_cluster_name
  postgres_enable_recovery              = var.postgres_enable_recovery

  prometheus_grafana_admin_password = var.prometheus_grafana_admin_password
  prometheus_storage_class          = var.prometheus_storage_class
  loki_storage_class                = var.loki_storage_class
}
