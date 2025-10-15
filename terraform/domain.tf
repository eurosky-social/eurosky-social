data "scaleway_domain_zone" "multi_az" {
  domain    = "eurosky.social"
  subdomain = "scw"
}

resource "scaleway_domain_record" "multi_az" {
  dns_zone = data.scaleway_domain_zone.multi_az.id
  name     = "ingress"
  type     = "A"
  data     = kubernetes_service.nginx["fr-par-1"].status[0].load_balancer[0].ingress[0].ip
  ttl      = 60

  http_service {
    ips = [
      kubernetes_service.nginx["fr-par-1"].status[0].load_balancer[0].ingress[0].ip,
      kubernetes_service.nginx["fr-par-2"].status[0].load_balancer[0].ingress[0].ip,
    ]
    must_contain = ""
    url          = "http://ingress.scw.eurosky.social/healthz"
    user_agent   = "scw_dns_healthcheck"
    strategy     = "all"
  }
}