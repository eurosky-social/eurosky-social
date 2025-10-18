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

# Wait for cluster pools to be ready before kubeconfig is usable
# This follows the official Scaleway provider pattern
# See: https://registry.terraform.io/providers/scaleway/scaleway/latest/docs/resources/k8s_cluster
#
# The null_resource is needed because when the cluster is created, its status is `pool_required`,
# but the kubeconfig can already be downloaded. This leads the kubernetes/helm providers to start
# creating objects, but the DNS entry for the Kubernetes master is not yet ready.
# That's why it's needed to wait for at least one pool.
resource "null_resource" "kubeconfig" {
  depends_on = [scaleway_k8s_pool.pool]

  triggers = {
    host                   = scaleway_k8s_cluster.kapsule_multi_az.kubeconfig[0].host
    token                  = scaleway_k8s_cluster.kapsule_multi_az.kubeconfig[0].token
    cluster_ca_certificate = scaleway_k8s_cluster.kapsule_multi_az.kubeconfig[0].cluster_ca_certificate
  }
}
