module "cert_manager" {
  source = "./cert-manager"

  scw_access_key = var.external_dns_access_key
  scw_secret_key = var.external_dns_secret_key
  acme_email     = var.cert_manager_acme_email
}

module "ingress_nginx" {
  source = "./ingress-nginx"

  zones          = var.ingress_nginx_zones
  cluster_domain = var.cluster_domain
  cloud_provider = "scaleway"

  depends_on = [module.cert_manager]
}

module "external_dns" {
  source = "./external-dns"

  access_key     = var.external_dns_access_key
  secret_key     = var.external_dns_secret_key
  cluster_domain = var.cluster_domain
  cloud_provider = "scaleway"

  depends_on = [module.ingress_nginx]
}

module "elastic" {
  source = "./elastic"

  storage_class  = var.elasticsearch_storage_class
  cluster_domain = var.cluster_domain

  depends_on = [module.cert_manager, module.ingress_nginx]
}

module "postgres" {
  source = "./postgres"

  storage_class         = var.backup_storage_class
  backup_s3_access_key  = var.backup_s3_access_key
  backup_s3_secret_key  = var.backup_s3_secret_key
  backup_s3_bucket      = var.backup_s3_bucket
  backup_s3_region      = var.backup_s3_region
  backup_s3_endpoint    = var.backup_s3_endpoint
  ozone_db_password     = var.ozone_db_password

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

  depends_on = [module.postgres, module.ingress_nginx]
}

module "pds" {
  source = "./pds"

  cluster_domain           = var.cluster_domain
  storage_provisioner      = var.pds_storage_provisioner
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

  depends_on = [module.ingress_nginx]
}
