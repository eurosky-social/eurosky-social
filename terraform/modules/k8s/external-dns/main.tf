resource "kubernetes_secret" "external_dns" {
  metadata {
    name      = "external-dns-${var.dns_provider}"
    namespace = "kube-system"
  }

  data = var.keys
}

resource "helm_release" "external_dns" {
  name       = "external-dns"
  namespace  = kubernetes_secret.external_dns.metadata[0].namespace
  repository = "https://kubernetes-sigs.github.io/external-dns/"
  chart      = "external-dns"
  version    = "1.15.0"

  values = [
    templatefile("${path.module}/external-dns-values.yaml", {
      dns_provider   = var.dns_provider
      keys           = var.keys
      cluster_domain = var.cluster_domain
    })
  ]

  depends_on = [kubernetes_secret.external_dns]
}

# TODO: Add high availability (replica: 2)
# TODO: Add podDisruptionBudget for HA
# TODO: Add serviceMonitor for Prometheus metrics
# TODO: Consider adding interval configuration (default 1m)
