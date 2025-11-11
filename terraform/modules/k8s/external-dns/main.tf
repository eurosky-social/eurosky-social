resource "kubernetes_secret" "external_dns" {
  metadata {
<<<<<<< HEAD
    name      = "external-dns"
    namespace = "kube-system"
  }

  data = {
    CF_API_TOKEN = var.api_token
  }
=======
    name      = "external-dns-${var.dns_provider}"
    namespace = "kube-system"
  }

  data = var.keys
>>>>>>> d173284 (WIP)
}

resource "helm_release" "external_dns" {
  name       = "external-dns"
  namespace  = kubernetes_secret.external_dns.metadata[0].namespace
  repository = "https://kubernetes-sigs.github.io/external-dns/"
  chart      = "external-dns"
  version    = "1.15.0"

  values = [
    templatefile("${path.module}/external-dns-values.yaml", {
<<<<<<< HEAD
      secret_name               = kubernetes_secret.external_dns.metadata[0].name
      secret_checksum           = sha256(jsonencode(kubernetes_secret.external_dns.data))
      sync_policy               = var.sync_policy
      txt_owner_id              = "${var.txt_owner_id}-${var.cluster_domain}"
      txt_prefix                = var.txt_prefix
      log_level                 = var.log_level
      log_format                = var.log_format
      resources_requests_cpu    = var.resources_requests_cpu
      resources_requests_memory = var.resources_requests_memory
      resources_limits_cpu      = var.resources_limits_cpu
      resources_limits_memory   = var.resources_limits_memory
=======
      dns_provider   = var.dns_provider
      keys           = var.keys
      cluster_domain = var.cluster_domain
>>>>>>> d173284 (WIP)
    })
  ]

  depends_on = [kubernetes_secret.external_dns]
}

# TODO: Add high availability (replica: 2)
# TODO: Add podDisruptionBudget for HA
# TODO: Consider adding interval configuration (default 1m)
