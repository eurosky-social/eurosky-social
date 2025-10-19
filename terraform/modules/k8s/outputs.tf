output "ozone_db_password" {
  description = "PostgreSQL password for Ozone user"
  value       = random_password.ozone_db_password.result
  sensitive   = true
}
