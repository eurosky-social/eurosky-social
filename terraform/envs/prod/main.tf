module "scaleway" {
  source = "../../modules/cloud_providers/scaleway"

  project_id                = var.project_id
  region                    = var.region
  domain                    = var.domain
  subdomain                 = var.subdomain
  zones                     = var.zones
  k8s_node_type             = var.k8s_node_type
  k8s_node_min_size         = var.k8s_node_min_size
  k8s_node_max_size         = var.k8s_node_max_size
  backup_bucket_name        = var.backup_bucket_name
  pds_blobstore_bucket_name = var.pds_blobstore_bucket_name
}

module "k8s" {
  source = "../../modules/k8s"

  kubeconfig_host                   = module.scaleway.kubeconfig_host
  kubeconfig_token                  = module.scaleway.kubeconfig_token
  kubeconfig_cluster_ca_certificate = module.scaleway.kubeconfig_cluster_ca_certificate

  external_dns_access_key = module.scaleway.external_dns_access_key
  external_dns_secret_key = module.scaleway.external_dns_secret_key

  ingress_nginx_zones = module.scaleway.zones
  cluster_domain          = module.scaleway.domain
  cert_manager_acme_email = var.cert_manager_acme_email

  ozone_cert_manager_issuer  = var.ozone_cert_manager_issuer
  pds_cert_manager_issuer    = var.pds_cert_manager_issuer
  kibana_cert_manager_issuer = var.kibana_cert_manager_issuer

  ozone_public_hostname = var.ozone_public_hostname
  elasticsearch_storage_class = var.elasticsearch_storage_class

  postgres_storage_class = var.postgres_storage_class
  backup_s3_access_key = module.scaleway.backup_s3_access_key
  backup_s3_secret_key = module.scaleway.backup_s3_secret_key
  backup_s3_bucket     = module.scaleway.backup_s3_bucket
  backup_s3_region     = module.scaleway.backup_s3_region
  backup_s3_endpoint   = module.scaleway.backup_s3_endpoint

  ozone_image           = var.ozone_image
  ozone_appview_url     = var.ozone_appview_url
  ozone_appview_did     = var.ozone_appview_did
  ozone_server_did      = var.ozone_server_did
  ozone_admin_dids      = var.ozone_admin_dids
  ozone_db_password     = var.ozone_db_password
  ozone_admin_password  = var.ozone_admin_password
  ozone_signing_key_hex = var.ozone_signing_key_hex

  pds_storage_provisioner  = module.scaleway.storage_provisioner
  pds_storage_size         = var.pds_storage_size
  pds_jwt_secret           = var.pds_jwt_secret
  pds_admin_password       = var.pds_admin_password
  pds_plc_rotation_key     = var.pds_plc_rotation_key
  pds_blobstore_bucket     = module.scaleway.pds_blobstore_bucket
  pds_blobstore_access_key = module.scaleway.pds_blobstore_access_key
  pds_blobstore_secret_key = module.scaleway.pds_blobstore_secret_key
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
}
