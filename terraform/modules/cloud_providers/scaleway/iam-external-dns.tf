# IAM for external-dns to manage Scaleway DNS
resource "scaleway_iam_application" "external_dns" {
  name        = "external-dns-${var.subdomain}"
  description = "Kubernetes external-dns controller for automatic DNS management"
}

resource "scaleway_iam_policy" "external_dns_policy" {
  name           = "external-dns-policy-${var.subdomain}"
  description    = "Allow external-dns to manage DNS records"
  application_id = scaleway_iam_application.external_dns.id

  rule {
    organization_id      = data.scaleway_account_project.main.organization_id
    permission_set_names = ["DomainsDNSFullAccess"]
  }
}

resource "scaleway_iam_api_key" "external_dns" {
  application_id = scaleway_iam_application.external_dns.id
  description    = "API key for external-dns"
}
