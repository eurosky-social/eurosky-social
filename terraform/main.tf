module "scaleway" {
  source = "./modules/cloud_providers/scaleway"

  project_id = var.project_id
  domain     = var.domain
  subdomain  = var.subdomain
  zones      = var.zones
}

module "k8s" {
  source = "./modules/k8s"

  external_dns_access_key     = module.scaleway.external_dns_access_key
  external_dns_secret_key     = module.scaleway.external_dns_secret_key

  ingress_nginx_zones         = module.scaleway.zones
  cluster_domain              = join(".", [module.scaleway.subdomain, module.scaleway.domain])

  cert_manager_acme_email = var.cert_manager_acme_email
}
