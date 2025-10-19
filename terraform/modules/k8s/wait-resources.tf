# Wait for cert-manager webhook to be ready before creating resources that depend on it
resource "null_resource" "wait_for_cert_manager_webhook" {
  triggers = {
    helm_revision = helm_release.cert_manager.metadata[0].revision
  }

  provisioner "local-exec" {
    command = <<-EOT
      echo "Waiting for cert-manager webhook to be ready..."
      kubectl wait --for=condition=Available --timeout=300s \
        deployment/cert-manager-webhook -n cert-manager

      # Additional wait to ensure CRDs are registered
      sleep 10
    EOT
  }

  depends_on = [
    helm_release.cert_manager
  ]
}

# Wait for ingress-nginx admission webhook to be ready
resource "null_resource" "wait_for_nginx_webhook" {
  triggers = {
    helm_revision = helm_release.nginx_ingress.metadata[0].revision
  }

  provisioner "local-exec" {
    command = <<-EOT
      echo "Waiting for ingress-nginx admission webhook to be ready..."
      kubectl wait --for=condition=Available --timeout=300s \
        deployment/ingress-nginx-controller -n ingress-nginx

      # Wait for webhook service to be ready
      kubectl wait --for=condition=Ready --timeout=300s \
        pod -l app.kubernetes.io/component=controller -n ingress-nginx

      # Additional wait for webhook endpoint to be fully operational
      sleep 10
    EOT
  }

  depends_on = [
    helm_release.nginx_ingress
  ]
}
