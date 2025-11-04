resource "helm_release" "metrics_server" {
  name       = "metrics-server"
  repository = "https://kubernetes-sigs.github.io/metrics-server/"
  chart      = "metrics-server"
  namespace  = "kube-system"
  version    = "3.13.0"

  # Required for UpCloud Managed Kubernetes
  set {
    name  = "args[0]"
    value = "--kubelet-insecure-tls"
  }
}
