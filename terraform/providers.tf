provider "scaleway" {
  region = var.region
}

provider "kubernetes" {
  host                   = module.scaleway.kubeconfig[0].host
  token                  = module.scaleway.kubeconfig[0].token
  cluster_ca_certificate = base64decode(module.scaleway.kubeconfig[0].cluster_ca_certificate)
}

provider "kubectl" {
  host                   = module.scaleway.kubeconfig[0].host
  token                  = module.scaleway.kubeconfig[0].token
  cluster_ca_certificate = base64decode(module.scaleway.kubeconfig[0].cluster_ca_certificate)
  load_config_file       = false
}

provider "helm" {
  kubernetes {
    host                   = module.scaleway.kubeconfig[0].host
    token                  = module.scaleway.kubeconfig[0].token
    cluster_ca_certificate = base64decode(module.scaleway.kubeconfig[0].cluster_ca_certificate)
  }
}
