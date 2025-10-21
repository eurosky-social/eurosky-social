module "scaleway" {
  source = "./modules/cloud_providers/scaleway"

  project_id = var.project_id
  region     = var.region
  domain     = var.domain
  subdomain  = var.subdomain
  zones      = var.zones
}

module "k8s" {
  source = "./modules/k8s"

  kubeconfig_host                   = module.scaleway.kubeconfig_host
  kubeconfig_token                  = module.scaleway.kubeconfig_token
  kubeconfig_cluster_ca_certificate = module.scaleway.kubeconfig_cluster_ca_certificate

  external_dns_access_key = module.scaleway.external_dns_access_key
  external_dns_secret_key = module.scaleway.external_dns_secret_key

  ingress_nginx_zones = module.scaleway.zones # TODO: Remove unnecessary output passthrough - k8s module shouldn't need zones if implicit dependency exists
  cluster_domain      = module.scaleway.domain

  cert_manager_acme_email     = var.cert_manager_acme_email
  elasticsearch_storage_class = "scw-bssd" # TODO: Extract hardcoded storage class to variable for cloud-agnostic design (see GUIDELINES.md Core Principles)

  backup_storage_class = "scw-bssd" # TODO: Extract hardcoded storage class to variable for cloud-agnostic design (see GUIDELINES.md Core Principles)
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

  pds_storage_provisioner  = "csi.scaleway.com" # TODO: Extract hardcoded CSI provisioner to variable for cloud-agnostic design (see GUIDELINES.md Core Principles)
  pds_jwt_secret           = var.pds_jwt_secret
  pds_admin_password       = var.pds_admin_password
  pds_plc_rotation_key     = var.pds_plc_rotation_key
  pds_blobstore_bucket     = module.scaleway.pds_blobstore_bucket
  pds_blobstore_access_key = module.scaleway.pds_blobstore_access_key
  pds_blobstore_secret_key = module.scaleway.pds_blobstore_secret_key
}
