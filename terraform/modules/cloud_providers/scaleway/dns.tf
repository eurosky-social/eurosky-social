resource "scaleway_domain_zone" "cluster_subdomain" {
  domain    = var.domain
  subdomain = var.subdomain
}
