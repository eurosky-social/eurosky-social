provider "upcloud" {
  # Authentication via environment variables:
  # export UPCLOUD_USERNAME="your-username"
  # export UPCLOUD_PASSWORD="your-password"
}

provider "kubernetes" {
  host                   = module.upcloud.kubeconfig_host
  client_certificate     = base64decode(module.upcloud.kubeconfig_client_certificate)
  client_key             = base64decode(module.upcloud.kubeconfig_client_key)
  cluster_ca_certificate = base64decode(module.upcloud.kubeconfig_cluster_ca_certificate)
}
