output "ingress_hostname" {
  description = "The hostname for the PLC ingress."
  value       = kubernetes_ingress_v1.plc.spec[0].rule[0].host
}