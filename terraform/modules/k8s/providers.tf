provider "kubernetes" {
  host                   = var.kubeconfig_host
  token                  = var.kubeconfig_token
  cluster_ca_certificate = base64decode(var.kubeconfig_cluster_ca_certificate)
}

provider "kubectl" {
  host                   = var.kubeconfig_host
  token                  = var.kubeconfig_token
  cluster_ca_certificate = base64decode(var.kubeconfig_cluster_ca_certificate)
  load_config_file       = false
}

provider "helm" {
  kubernetes {
    host                   = var.kubeconfig_host
    token                  = var.kubeconfig_token
    cluster_ca_certificate = base64decode(var.kubeconfig_cluster_ca_certificate)
  }
}
