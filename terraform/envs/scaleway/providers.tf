provider "kubernetes" {
  host                   = module.scaleway.kubeconfig_host
  token                  = module.scaleway.kubeconfig_token
  cluster_ca_certificate = base64decode(module.scaleway.kubeconfig_cluster_ca_certificate)
}

provider "kubectl" {
  host                   = module.scaleway.kubeconfig_host
  token                  = module.scaleway.kubeconfig_token
  cluster_ca_certificate = base64decode(module.scaleway.kubeconfig_cluster_ca_certificate)
  load_config_file       = false
}

provider "helm" {
  kubernetes {
    host                   = module.scaleway.kubeconfig_host
    token                  = module.scaleway.kubeconfig_token
    cluster_ca_certificate = base64decode(module.scaleway.kubeconfig_cluster_ca_certificate)
  }
}
