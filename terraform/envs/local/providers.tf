# Provider configurations for local k3d environment
# Uses local kubeconfig file for authentication

provider "kubernetes" {
  config_path    = "~/.kube/config"
  config_context = "k3d-eurosky-local"
}

provider "kubectl" {
  config_path    = "~/.kube/config"
  config_context = "k3d-eurosky-local"
}

provider "helm" {
  kubernetes {
    config_path    = "~/.kube/config"
    config_context = "k3d-eurosky-local"
  }
}
