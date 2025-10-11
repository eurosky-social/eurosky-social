output "container_id" {
  description = "The ID of the Ozone container"
  value       = scaleway_container.ozone.id
}

output "container_url" {
  description = "The URL of the Ozone container"
  value       = scaleway_container.ozone.domain_name
}

output "custom_domain" {
  description = "The custom domain for Ozone"
  value       = var.hostname
}

output "database_endpoint" {
  description = "The PostgreSQL serverless database endpoint"
  value       = scaleway_sdb_sql_database.ozone.endpoint
  sensitive   = true
}

output "database_name" {
  description = "The name of the PostgreSQL database"
  value       = scaleway_sdb_sql_database.ozone.name
}

output "iam_application_id" {
  description = "The IAM application ID for database access"
  value       = scaleway_iam_application.ozone.id
}

output "iam_api_key" {
  description = "The IAM API key for database access"
  value       = scaleway_iam_api_key.ozone.secret_key
  sensitive   = true
}
