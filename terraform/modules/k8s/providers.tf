provider "kubernetes" {
  host                   = var.kubeconfig_host
  token                  = var.kubeconfig_token != "" ? var.kubeconfig_token : null
  client_certificate     = var.kubeconfig_client_certificate != "" ? base64decode(var.kubeconfig_client_certificate) : null
  client_key             = var.kubeconfig_client_key != "" ? base64decode(var.kubeconfig_client_key) : null
  cluster_ca_certificate = base64decode(var.kubeconfig_cluster_ca_certificate)
}

provider "kubectl" {
  host                   = var.kubeconfig_host
  token                  = var.kubeconfig_token != "" ? var.kubeconfig_token : null
  client_certificate     = var.kubeconfig_client_certificate != "" ? base64decode(var.kubeconfig_client_certificate) : null
  client_key             = var.kubeconfig_client_key != "" ? base64decode(var.kubeconfig_client_key) : null
  cluster_ca_certificate = base64decode(var.kubeconfig_cluster_ca_certificate)
  load_config_file       = false
}

provider "helm" {
  kubernetes {
    host                   = var.kubeconfig_host
    token                  = var.kubeconfig_token != "" ? var.kubeconfig_token : null
    client_certificate     = var.kubeconfig_client_certificate != "" ? base64decode(var.kubeconfig_client_certificate) : null
    client_key             = var.kubeconfig_client_key != "" ? base64decode(var.kubeconfig_client_key) : null
    cluster_ca_certificate = base64decode(var.kubeconfig_cluster_ca_certificate)
  }
}
