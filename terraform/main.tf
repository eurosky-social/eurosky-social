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

  ingress_nginx_zones = module.scaleway.zones
  cluster_domain      = join(".", [module.scaleway.subdomain, module.scaleway.domain])

  cert_manager_acme_email     = var.cert_manager_acme_email
  elasticsearch_storage_class = "scw-bssd"

  postgres_storage_class           = "scw-bssd"
  postgres_backup_access_key       = module.scaleway.postgres_backup_access_key
  postgres_backup_secret_key       = module.scaleway.postgres_backup_secret_key
  postgres_backup_destination_path = module.scaleway.postgres_backup_destination_path
  postgres_backup_endpoint_url     = module.scaleway.postgres_backup_endpoint_url

  ozone_image            = var.ozone_image
  ozone_appview_url      = var.ozone_appview_url
  ozone_appview_did      = var.ozone_appview_did
  ozone_server_did       = var.ozone_server_did
  ozone_admin_dids       = var.ozone_admin_dids
  ozone_db_password      = module.k8s.ozone_db_password
  ozone_admin_password   = var.ozone_admin_password
  ozone_signing_key_hex  = var.ozone_signing_key_hex
}
