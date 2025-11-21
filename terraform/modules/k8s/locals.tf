# Use kubeconfig_path variable when explicit kubeconfig not provided
locals {
  use_kubeconfig_file = var.kubeconfig_host == ""
}
