output "ingress_hostname" {
  description = "The hostname for the PDS ingress."
  value       = kubernetes_ingress_v1.pds[0].spec[0].rule[0].host
}
