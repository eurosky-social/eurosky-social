resource "scaleway_vpc" "vpc_multi_az" {
  name = "vpc-multi-az-${var.subdomain}"
  tags = ["multi-az"]
}

resource "scaleway_vpc_private_network" "pn_multi_az" {
  name   = "pn-multi-az-${var.subdomain}"
  vpc_id = scaleway_vpc.vpc_multi_az.id
  tags   = ["multi-az"]
}

# Public Gateway for pod egress when nodes have private IPs only
resource "scaleway_vpc_public_gateway" "pgw_multi_az" {
  name = "pgw-multi-az-${var.subdomain}"
  type = "VPC-GW-S"
  tags = ["multi-az"]
}

resource "scaleway_vpc_gateway_network" "pn_gateway" {
  gateway_id         = scaleway_vpc_public_gateway.pgw_multi_az.id
  private_network_id = scaleway_vpc_private_network.pn_multi_az.id
  enable_masquerade  = true
  ipam_config {
    push_default_route = true
  }
  depends_on = [scaleway_vpc_public_gateway.pgw_multi_az]
}
