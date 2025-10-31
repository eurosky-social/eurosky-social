resource "kubernetes_secret" "external_dns" {
  metadata {
    name      = "external-dns"
    namespace = "kube-system"
  }

  data = {
    CF_API_TOKEN = var.api_token
  }
}

resource "helm_release" "external_dns" {
  name       = "external-dns"
  namespace  = kubernetes_secret.external_dns.metadata[0].namespace
  repository = "https://kubernetes-sigs.github.io/external-dns/"
  chart      = "external-dns"
  version    = "1.15.0"

  values = [
    templatefile("${path.module}/external-dns-values.yaml", {
      secret_name               = kubernetes_secret.external_dns.metadata[0].name
      sync_policy               = var.sync_policy
      txt_owner_id              = "${var.txt_owner_id}-${var.cluster_domain}"
      txt_prefix                = var.txt_prefix
      log_level                 = var.log_level
      log_format                = var.log_format
      resources_requests_cpu    = var.resources_requests_cpu
      resources_requests_memory = var.resources_requests_memory
      resources_limits_cpu      = var.resources_limits_cpu
      resources_limits_memory   = var.resources_limits_memory
    })
  ]
}

# TODO: Add high availability (replica: 2)
# TODO: Add podDisruptionBudget for HA
# TODO: Consider adding interval configuration (default 1m)
