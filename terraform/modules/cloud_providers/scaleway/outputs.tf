output "domain" {
  description = "Base domain for DNS records"
  value       = var.domain
}

output "subdomain" {
  description = "Subdomain prefix"
  value       = var.subdomain
}

output "zones" {
  description = "Availability zones"
  value       = var.zones
}

output "external_dns_access_key" {
  description = "External-DNS Scaleway access key"
  value       = scaleway_iam_api_key.external_dns.access_key
  sensitive   = true
}

output "external_dns_secret_key" {
  description = "External-DNS Scaleway secret key"
  value       = scaleway_iam_api_key.external_dns.secret_key
  sensitive   = true
}

output "kubeconfig" {
  description = "Kubernetes cluster kubeconfig"
  value       = scaleway_k8s_cluster.kapsule_multi_az.kubeconfig
  sensitive   = true
}
