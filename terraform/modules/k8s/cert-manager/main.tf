resource "helm_release" "cert_manager" {
  name      = "cert-manager"
  namespace = "cert-manager"

  create_namespace = true

  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  version    = "v1.16.2"

  values = [
    file("${path.module}/values.yaml")
  ]
}

resource "kubernetes_secret" "cert_manager_cloudflare" {
  metadata {
    name      = "cert-manager-cloudflare"
    namespace = helm_release.cert_manager.namespace
  }

  data = {
    api-token = var.cloudflare_dns_api_token
  }
}

resource "kubectl_manifest" "cluster_issuer" {
  for_each = {
    "letsencrypt-prod" = {
      server = "https://acme-v02.api.letsencrypt.org/directory"
    }
    "letsencrypt-staging" = {
      server = "https://acme-staging-v02.api.letsencrypt.org/directory"
    }
  }

  yaml_body = templatefile("${path.module}/cluster-issuer.yaml", {
    name             = each.key
    server           = each.value.server
    email            = var.acme_email
    secret_name      = kubernetes_secret.cert_manager_cloudflare.metadata[0].name
    secret_namespace = kubernetes_secret.cert_manager_cloudflare.metadata[0].namespace
  })

  server_side_apply = true
  wait              = true

  depends_on = [
    helm_release.cert_manager,
    kubernetes_secret.cert_manager_cloudflare
  ]
}

# TODO: Add Let's Encrypt rate limit monitoring (50 certs/week limit)
