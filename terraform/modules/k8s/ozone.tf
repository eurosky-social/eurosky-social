locals {
  ozone_hostname   = "ozone.${var.cluster_domain}"
  ozone_public_url = "https://${local.ozone_hostname}"
}

resource "kubernetes_namespace" "ozone" {
  metadata {
    name = "ozone"
  }
}

data "kubernetes_secret" "postgres_ca" {
  metadata {
    name      = local.postgres_ca_secret_name
    namespace = kubernetes_namespace.databases.metadata[0].name
  }

  depends_on = [
    kubectl_manifest.postgres_cluster
  ]
}

resource "kubernetes_secret" "postgres_ca_ozone" {
  metadata {
    name      = data.kubernetes_secret.postgres_ca.metadata[0].name
    namespace = kubernetes_namespace.ozone.metadata[0].name
  }

  data = data.kubernetes_secret.postgres_ca.data
  type = data.kubernetes_secret.postgres_ca.type
}

resource "kubectl_manifest" "ozone_configmap" {
  yaml_body = templatefile("${path.module}/ozone-configmap.yaml", {
    namespace         = kubernetes_namespace.ozone.metadata[0].name
    ozone_public_url  = local.ozone_public_url
    ozone_appview_url = var.ozone_appview_url
    ozone_appview_did = var.ozone_appview_did
    ozone_server_did  = var.ozone_server_did
    ozone_admin_dids  = var.ozone_admin_dids
  })

  server_side_apply = true
  wait              = true
}

resource "kubectl_manifest" "ozone_secret" {
  yaml_body = templatefile("${path.module}/ozone-secret.yaml", {
    namespace                = kubernetes_namespace.ozone.metadata[0].name
    db_password_urlencoded   = urlencode(var.ozone_db_password)
    ozone_admin_password     = var.ozone_admin_password
    ozone_signing_key_hex    = var.ozone_signing_key_hex
    postgres_cluster_name    = kubectl_manifest.postgres_cluster.name
    postgres_namespace       = kubernetes_namespace.databases.metadata[0].name
  })

  server_side_apply = true
  wait              = true
}

resource "kubectl_manifest" "ozone_deployment" {
  yaml_body = templatefile("${path.module}/ozone-deployment.yaml", {
    namespace         = kubernetes_namespace.ozone.metadata[0].name
    ozone_image       = var.ozone_image
    ca_secret_name    = kubernetes_secret.postgres_ca_ozone.metadata[0].name
  })

  server_side_apply = true
  wait              = true
}

resource "kubectl_manifest" "ozone_service" {
  yaml_body = templatefile("${path.module}/ozone-service.yaml", {
    namespace = kubernetes_namespace.ozone.metadata[0].name
  })

  server_side_apply = true
  wait              = true
}

resource "kubectl_manifest" "ozone_ingress" {
  yaml_body = templatefile("${path.module}/ozone-ingress.yaml", {
    namespace             = kubernetes_namespace.ozone.metadata[0].name
    ozone_hostname        = local.ozone_hostname
    ozone_cluster_domain  = var.cluster_domain
  })

  server_side_apply = true
  wait              = true

  depends_on = [
    null_resource.wait_for_nginx_webhook
  ]
}
