# Get current project/organization info
data "scaleway_account_project" "main" {
  project_id = var.project_id
}

# IAM for external-dns to manage Scaleway DNS
resource "scaleway_iam_application" "external_dns" {
  name = "external-dns"
  description = "Kubernetes external-dns controller for automatic DNS management"
}

resource "scaleway_iam_policy" "external_dns_policy" {
  name           = "external-dns-policy"
  description    = "Allow external-dns to manage DNS records"
  application_id = scaleway_iam_application.external_dns.id

  rule {
    organization_id = data.scaleway_account_project.main.organization_id
    permission_set_names = [
      "DomainsDNSFullAccess",
      "DomainsDNSReadOnly"
    ]
  }
}

resource "scaleway_iam_api_key" "external_dns" {
  application_id = scaleway_iam_application.external_dns.id
  description    = "API key for external-dns"
}

# Store credentials in Kubernetes secret
resource "kubernetes_secret" "external_dns" {
  metadata {
    name      = "external-dns-scaleway"
    namespace = "kube-system"
  }

  data = {
    SCW_ACCESS_KEY = scaleway_iam_api_key.external_dns.access_key
    SCW_SECRET_KEY = scaleway_iam_api_key.external_dns.secret_key
  }

  depends_on = [scaleway_k8s_pool.pool-multi-az-v2]
}

# Deploy external-dns via Helm
resource "helm_release" "external_dns" {
  name       = "external-dns"
  namespace  = "kube-system"
  repository = "https://kubernetes-sigs.github.io/external-dns/"
  chart      = "external-dns"
  version    = "1.15.0"

  depends_on = [
    scaleway_k8s_pool.pool-multi-az-v2,
    kubernetes_secret.external_dns
  ]

  values = [
    <<-EOT
    provider: scaleway

    env:
      - name: SCW_ACCESS_KEY
        valueFrom:
          secretKeyRef:
            name: external-dns-scaleway
            key: SCW_ACCESS_KEY
      - name: SCW_SECRET_KEY
        valueFrom:
          secretKeyRef:
            name: external-dns-scaleway
            key: SCW_SECRET_KEY

    # Only manage A records and TXT records (for ownership)
    sources:
      - service
      - ingress

    # Match your domain
    domainFilters:
      - scw.eurosky.social

    # Sync policy: sync or upsert-only (safer)
    policy: sync

    # Registry for tracking managed records
    registry: txt
    txtOwnerId: "k8s-external-dns"
    txtPrefix: "_external-dns."

    # Logging
    logLevel: info
    logFormat: json

    # Resource limits
    resources:
      requests:
        cpu: 50m
        memory: 64Mi
      limits:
        cpu: 200m
        memory: 128Mi
    EOT
  ]
}
