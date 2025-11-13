locals {
  hostname         = "ozone.${var.cluster_domain}"
  ozone_public_url = "https://${local.hostname}"

  # Rendered templates stored in locals
  ozone_configmap_yaml = templatefile("${path.module}/ozone-configmap.yaml", {
    namespace         = var.namespace
    ozone_public_url  = local.ozone_public_url
    ozone_appview_url = var.ozone_appview_url
    ozone_appview_did = var.ozone_appview_did
    ozone_server_did  = var.ozone_server_did
    ozone_admin_dids  = var.ozone_admin_dids
    pds_hostname      = var.pds_hostname
  })

  ozone_secret_yaml = templatefile("${path.module}/ozone-secret.yaml", {
    namespace              = var.namespace
    db_password_urlencoded = urlencode(var.ozone_db_password)
    ozone_admin_password   = var.ozone_admin_password
    ozone_signing_key_hex  = var.ozone_signing_key_hex
    postgres_cluster_name  = var.postgres_cluster_name
    postgres_namespace     = var.postgres_namespace
    postgres_pooler_name   = var.postgres_pooler_name
  })

  # Checksums computed from rendered YAML (automatically tracks all changes)
  config_checksum = sha256(local.ozone_configmap_yaml)
  secret_checksum = sha256(local.ozone_secret_yaml)
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
  yaml_body = local.ozone_configmap_yaml

  server_side_apply = true
  wait              = true
}

resource "kubectl_manifest" "ozone_secret" {
  # TODO: Replace with external secret management solution (External Secrets Operator, Sealed Secrets)
  yaml_body = local.ozone_secret_yaml

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

  depends_on = [
    kubectl_manifest.ozone_configmap,
    kubectl_manifest.ozone_secret
  ]
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
    hostname             = local.hostname
    ozone_cluster_domain = var.cluster_domain
  })

  server_side_apply = true
  wait              = true
}

resource "kubernetes_config_map" "ozone_log_alerts" {
  metadata {
    name      = "ozone-log-alerts"
    namespace = "loki"
    labels = {
      loki_rule = "1"
    }
  }

  data = {
    "ozone-log-alerts.yaml" = file("${path.module}/log-alerts.yaml")
  }
}

# TODO: Add HorizontalPodAutoscaler for Ozone (2-5 replicas, 70% CPU target)
# TODO: Add PodDisruptionBudget for Ozone (minAvailable: 1)
# TODO: Add Ozone application metrics + ServiceMonitor 
# TODO: Consider progressive rollout strategy (Argo Rollouts/Flagger)
# TODO: Add NetworkPolicy to restrict ingress/egress
# TODO: Document disaster recovery procedures
