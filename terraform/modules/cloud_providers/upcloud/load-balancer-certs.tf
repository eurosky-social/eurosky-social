resource "upcloud_loadbalancer_dynamic_certificate_bundle" "ingress" {
  name = "${var.partition}-ingress-auto-tls"
  hostnames = var.ingress_hostnames
  key_type = "ecdsa"
}

