# When kubeconfig_host is empty, providers use kubeconfig_path file
provider "kubernetes" {
  host                   = var.kubeconfig_host != "" ? var.kubeconfig_host : null
  token                  = var.kubeconfig_token != "" ? var.kubeconfig_token : null
  client_certificate     = var.kubeconfig_client_certificate != "" ? base64decode(var.kubeconfig_client_certificate) : null
  client_key             = var.kubeconfig_client_key != "" ? base64decode(var.kubeconfig_client_key) : null
  cluster_ca_certificate = var.kubeconfig_cluster_ca_certificate != "" ? base64decode(var.kubeconfig_cluster_ca_certificate) : null
  config_path            = var.kubeconfig_host == "" ? pathexpand(var.kubeconfig_path) : null
}

provider "kubectl" {
  host                   = var.kubeconfig_host != "" ? var.kubeconfig_host : null
  token                  = var.kubeconfig_token != "" ? var.kubeconfig_token : null
  client_certificate     = var.kubeconfig_client_certificate != "" ? base64decode(var.kubeconfig_client_certificate) : null
  client_key             = var.kubeconfig_client_key != "" ? base64decode(var.kubeconfig_client_key) : null
  cluster_ca_certificate = var.kubeconfig_cluster_ca_certificate != "" ? base64decode(var.kubeconfig_cluster_ca_certificate) : null
  load_config_file       = var.kubeconfig_host == ""
  config_path            = var.kubeconfig_host == "" ? pathexpand(var.kubeconfig_path) : null
}

provider "helm" {
  kubernetes {
    host                   = var.kubeconfig_host != "" ? var.kubeconfig_host : null
    token                  = var.kubeconfig_token != "" ? var.kubeconfig_token : null
    client_certificate     = var.kubeconfig_client_certificate != "" ? base64decode(var.kubeconfig_client_certificate) : null
    client_key             = var.kubeconfig_client_key != "" ? base64decode(var.kubeconfig_client_key) : null
    cluster_ca_certificate = var.kubeconfig_cluster_ca_certificate != "" ? base64decode(var.kubeconfig_cluster_ca_certificate) : null
    config_path            = var.kubeconfig_host == "" ? pathexpand(var.kubeconfig_path) : null
  }
}
