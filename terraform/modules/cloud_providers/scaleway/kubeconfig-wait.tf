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
