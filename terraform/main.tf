resource "scaleway_vpc" "vpc_multi_az" {
  name = "vpc-multi-az"
  tags = ["multi-az"]
}

resource "scaleway_vpc_private_network" "pn_multi_az" {
  name   = "pn-multi-az"
  vpc_id = scaleway_vpc.vpc_multi_az.id
  tags   = ["multi-az"]
}

resource "scaleway_k8s_cluster" "kapsule_multi_az" {
  name = "kapsule-multi-az"
  tags = ["multi-az"]

  type    = "kapsule"
  version = "1.34"
  cni     = "cilium"

  delete_additional_resources = true

  autoscaler_config {
    ignore_daemonsets_utilization = true
    balance_similar_node_groups   = true
  }

  auto_upgrade {
    enable                        = true
    maintenance_window_day        = "sunday"
    maintenance_window_start_hour = 2
  }

  private_network_id = scaleway_vpc_private_network.pn_multi_az.id
}

output "kapsule" {
  description = "Kapsule cluster id"
  value       = scaleway_k8s_cluster.kapsule_multi_az.id
}

resource "scaleway_k8s_pool" "pool-multi-az-v2" {
  for_each = toset(["fr-par-1", "fr-par-2"])

  name                   = "pool-v2-${each.value}"
  zone                   = each.value
  tags                   = ["multi-az", "v2"]
  cluster_id             = scaleway_k8s_cluster.kapsule_multi_az.id
  node_type              = "DEV1-M" # POP2-2C-8G min with SLA
  size                   = 1 # for prod perhaps we want more per AZ
  min_size               = 1
  max_size               = 1
  autoscaling            = true
  autohealing            = true
  container_runtime      = "containerd"
  root_volume_size_in_gb = 20 # Minimum allowed by Scaleway
  root_volume_type       = "l_ssd"
}