# Create a router for the network
resource "upcloud_router" "main" {
  name = "${var.partition}-router"
}

# Create a network for the cluster
resource "upcloud_network" "main" {
  name = "${var.partition}-net"
  zone = var.zone

  ip_network {
    address            = var.ip_network_range
    dhcp               = true
    dhcp_default_route = true
    family             = "IPv4"
  }

  router = upcloud_router.main.id

  labels = {
    managed-by = "terraform"
    project    = var.partition
  }
}

# Create a Managed NAT Gateway for Internet connectivity from the SDN network
resource "upcloud_gateway" "main" {
  name     = "${var.partition}-gw"
  zone     = var.zone
  features = ["nat"]
  plan     = "essentials" # TODO: change plan for prod
  router {
    id = upcloud_router.main.id
  }

  labels = {
    managed-by = "terraform"
    project    = var.partition
  }
}

# Create the Kubernetes cluster
resource "upcloud_kubernetes_cluster" "main" {
  name                = "${var.partition}-cluster"
  network             = upcloud_network.main.id
  zone                = var.zone
  private_node_groups = true
  # TODO: setup bastion access and restrict this further
  control_plane_ip_filter = ["0.0.0.0/0"]

  labels = {
    managed-by = "terraform"
    project    = var.partition
  }

  depends_on = [upcloud_gateway.main]
}

# Create the node group
# TODO: For production, consider:
# - Use larger plan (e.g., 2xCPU-4GB or higher)
# - Add multiple node groups for different workload types
# - Configure anti_affinity based on HA requirements
# - Add taints for workload isolation
resource "upcloud_kubernetes_node_group" "main" {
  name = "${var.partition}-nodes"

  cluster       = upcloud_kubernetes_cluster.main.id
  node_count    = var.k8s_node_count_min
  plan          = var.k8s_node_plan
  anti_affinity = true

  labels = {
    managed-by = "terraform"
    project    = var.partition
  }

  // TODO: Consider adding taints for production workloads
  # taint {
  #   effect = "NoExecute"
  #   key    = "workload"
  #   value  = each.key # ["core", "database", "app"]
  # }
  ssh_keys = []

  # Ignore node_count changes made by Cluster Autoscaler
  lifecycle {
    ignore_changes = [node_count]
  }
}

# Fetch cluster details after creation to get real kubeconfig
data "upcloud_kubernetes_cluster" "main" {
  depends_on = [upcloud_kubernetes_node_group.main]
  id         = upcloud_kubernetes_cluster.main.id
}

