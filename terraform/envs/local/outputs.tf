# Local K3d Environment Outputs
# Note: Kubernetes connection details are managed via ~/.kube/config

output "cluster_domain" {
  description = "The cluster domain for accessing services"
  value       = var.cluster_domain
}
