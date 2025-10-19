# TODO: Add resource limits (requests.cpu=10m, requests.memory=32Mi, limits.memory=128Mi)
# TODO: Add HA config (replicaCount=2, webhook.replicaCount=2, podDisruptionBudget.enabled=true)
# TODO: Add security context (runAsNonRoot=true, allowPrivilegeEscalation=false)
# TODO: Add global.priorityClassName=system-cluster-critical for production
# TODO: Enable prometheus.enabled=true for monitoring
# TODO: Consider moving to values file approach instead of multiple set blocks
resource "helm_release" "cert_manager" {
  name      = "cert-manager"
  namespace = "cert-manager"

  create_namespace = true

  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  version    = "v1.16.2"

  set {
    name  = "crds.enabled"
    value = "true"
  }
}

resource "kubernetes_secret" "cert_manager_scaleway" {
  metadata {
    name      = "cert-manager-scaleway"
    namespace = helm_release.cert_manager.namespace
  }

  data = {
    SCW_ACCESS_KEY = var.external_dns_access_key
    SCW_SECRET_KEY = var.external_dns_secret_key
  }
}

# Using DNS-01 challenge for local dev
resource "helm_release" "cert_manager_webhook_scaleway" {
  name       = "scaleway-certmanager-webhook"
  namespace  = helm_release.cert_manager.namespace
  repository = "https://helm.scw.cloud/"
  chart      = "scaleway-certmanager-webhook"

  set {
    name  = "secret.accessKey"
    value = kubernetes_secret.cert_manager_scaleway.data["SCW_ACCESS_KEY"]
  }

  set {
    name  = "secret.secretKey"
    value = kubernetes_secret.cert_manager_scaleway.data["SCW_SECRET_KEY"]
  }
}

# TODO: Add rate limit handling for Let's Encrypt production (50 certs/week limit)
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
    name               = each.key
    server             = each.value.server
    email              = var.cert_manager_acme_email
    secret_name        = kubernetes_secret.cert_manager_scaleway.metadata[0].name
    secret_namespace   = kubernetes_secret.cert_manager_scaleway.metadata[0].namespace
    webhook_chart_name = helm_release.cert_manager_webhook_scaleway.name
  })

  wait = true

  depends_on = [
    null_resource.wait_for_cert_manager_webhook
  ]
}
