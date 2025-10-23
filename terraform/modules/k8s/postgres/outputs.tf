output "namespace" {
  description = "PostgreSQL namespace"
  value       = kubernetes_namespace.databases.metadata[0].name
}

output "cluster_name" {
  description = "PostgreSQL cluster name"
  value       = var.postgres_cluster_name
}

output "ca_secret_name" {
  description = "PostgreSQL CA secret name"
  value       = local.postgres_ca_secret_name
}

output "pooler_name" {
  description = "PostgreSQL pooler service name"
  value       = local.pooler_name
}
