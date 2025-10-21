output "namespace" {
  description = "PostgreSQL namespace"
  value       = kubernetes_namespace.databases.metadata[0].name
}

output "cluster_name" {
  description = "PostgreSQL cluster name"
  value       = local.postgres_cluster_name
}

output "ca_secret_name" {
  description = "PostgreSQL CA secret name"
  value       = local.postgres_ca_secret_name
}
