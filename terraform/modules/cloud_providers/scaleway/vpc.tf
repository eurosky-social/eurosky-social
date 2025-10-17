resource "scaleway_vpc" "vpc_multi_az" {
  name = "vpc-multi-az"
  tags = ["multi-az"]
}

resource "scaleway_vpc_private_network" "pn_multi_az" {
  name   = "pn-multi-az"
  vpc_id = scaleway_vpc.vpc_multi_az.id
  tags   = ["multi-az"]
}
