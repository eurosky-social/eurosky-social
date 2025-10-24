locals {
  default_hostname = "ozone.${var.cluster_domain}"
  public_hostname  = var.ozone_public_hostname
  ozone_hostname   = coalesce(local.public_hostname, local.default_hostname)
  ozone_public_url = "https://${local.ozone_hostname}"
  ozone_hostnames  = compact([local.default_hostname, local.public_hostname])

  # ConfigMap/Secret checksums for triggering rolling updates
  config_checksum = sha256(jsonencode({
    ozone_public_url  = local.ozone_public_url
    ozone_appview_url = var.ozone_appview_url
    ozone_appview_did = var.ozone_appview_did
    ozone_server_did  = var.ozone_server_did
    ozone_admin_dids  = var.ozone_admin_dids
  }))

  secret_checksum = sha256(jsonencode({
    ozone_db_password     = var.ozone_db_password
    ozone_admin_password  = var.ozone_admin_password
    ozone_signing_key_hex = var.ozone_signing_key_hex
  }))
}

resource "kubernetes_namespace" "ozone" {
  metadata {
    name = var.namespace
  }
}

data "kubernetes_secret" "postgres_ca" {
  metadata {
    name      = var.postgres_ca_secret_name
    namespace = var.postgres_namespace
  }
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
  # TODO: Replace with external secret management solution (External Secrets Operator, Sealed Secrets)
  yaml_body = templatefile("${path.module}/ozone-secret.yaml", {
    namespace              = kubernetes_namespace.ozone.metadata[0].name
    db_password_urlencoded = urlencode(var.ozone_db_password)
    ozone_admin_password   = var.ozone_admin_password
    ozone_signing_key_hex  = var.ozone_signing_key_hex
    postgres_cluster_name  = var.postgres_cluster_name
    postgres_namespace     = var.postgres_namespace
    postgres_pooler_name   = var.postgres_pooler_name
  })

  server_side_apply = true
  wait              = true
}

resource "kubectl_manifest" "ozone_deployment" {
  yaml_body = templatefile("${path.module}/ozone-deployment.yaml", {
    namespace       = kubernetes_namespace.ozone.metadata[0].name
    ozone_image     = var.ozone_image
    ca_secret_name  = kubernetes_secret.postgres_ca_ozone.metadata[0].name
    config_checksum = local.config_checksum
    secret_checksum = local.secret_checksum
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
    namespace            = kubernetes_namespace.ozone.metadata[0].name
    ozone_hostnames      = local.ozone_hostnames
    ozone_cluster_domain = var.cluster_domain
    cert_manager_issuer  = var.cert_manager_issuer
  })

  server_side_apply = true
  wait              = true
}

# TODO: Add HorizontalPodAutoscaler for Ozone (2-5 replicas, 70% CPU target)
# TODO: Add PodDisruptionBudget for Ozone (minAvailable: 1)
# TODO: Add ServiceMonitor for Ozone observability
# TODO: Consider progressive rollout strategy (Argo Rollouts/Flagger)
# TODO: Add NetworkPolicy to restrict ingress/egress
# TODO: Document disaster recovery procedures
