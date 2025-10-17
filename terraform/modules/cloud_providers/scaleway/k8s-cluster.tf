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

resource "scaleway_instance_placement_group" "k8s" {
  for_each = toset(var.zones)

  name        = "k8s-${each.key}"
  zone        = each.key
  policy_type = "max_availability"
  policy_mode = "enforced"
}

resource "scaleway_k8s_pool" "pool" {
  for_each = toset(var.zones)

  name       = "pool-v2-${each.key}"
  zone       = each.key
  tags       = ["multi-az", "v2"]
  cluster_id = scaleway_k8s_cluster.kapsule_multi_az.id

  node_type              = "DEV1-M"
  size                   = 1
  min_size               = 1
  max_size               = 1
  autoscaling            = true
  autohealing            = true
  container_runtime      = "containerd"
  root_volume_size_in_gb = 20
  root_volume_type       = "l_ssd"

  # TODO: add a placement group per host per zone
  placement_group_id = scaleway_instance_placement_group.k8s[each.key].id

  # TODO: Enable zero-downtime upgrades when pool size > 1 (requires max_unavailable >= 1 for Scaleway API)
  # upgrade_policy {
  #   max_surge       = 1
  #   max_unavailable = 0
  # }
}
