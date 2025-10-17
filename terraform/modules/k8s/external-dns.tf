resource "kubernetes_secret" "external_dns" {
  metadata {
    # TODO this is tied to the cloud provider
    name      = "external-dns-scaleway"
    namespace = "kube-system"
  }

  data = {
    SCW_ACCESS_KEY = var.external_dns_access_key
    SCW_SECRET_KEY = var.external_dns_secret_key
  }
}

# TODO: Add high availability (replica: 2)
# TODO: Add podDisruptionBudget for HA
# TODO: Add serviceMonitor for Prometheus metrics
# TODO: Consider adding interval configuration (default 1m)
resource "helm_release" "external_dns" {
  name       = "external-dns"
  namespace  = kubernetes_secret.external_dns.metadata[0].namespace
  repository = "https://kubernetes-sigs.github.io/external-dns/"
  chart      = "external-dns"
  version    = "1.15.0"

  values = [
    templatefile("${path.module}/external-dns-values.yaml", {
      secret_name               = kubernetes_secret.external_dns.metadata[0].name
      cluster_domain            = var.cluster_domain
      sync_policy               = "sync"
      txt_owner_id              = "k8s-external-dns"
      txt_prefix                = "_external-dns."
      log_level                 = "info"
      log_format                = "json"
      resources_requests_cpu    = "50m"
      resources_requests_memory = "64Mi"
      resources_limits_cpu      = "200m"
      resources_limits_memory   = "128Mi"
    })
  ]
}
