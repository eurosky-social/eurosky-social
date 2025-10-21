locals {
  pds_hostname     = "pds.${var.cluster_domain}"
  pds_public_url   = "https://${local.pds_hostname}"
  pds_version      = var.pds_version
  pds_storage_size = var.pds_storage_size
}

resource "kubernetes_namespace" "pds" {
  metadata {
    name = var.namespace
  }
}

resource "kubectl_manifest" "pds_storageclass" {
  yaml_body = templatefile("${path.module}/pds-storageclass.yaml", {
    storage_provisioner = var.storage_provisioner
  })

  server_side_apply = true
  wait              = true
}

resource "kubectl_manifest" "pds_configmap_litestream" {
  yaml_body = templatefile("${path.module}/pds-configmap-litestream.yaml", {
    namespace       = kubernetes_namespace.pds.metadata[0].name
    backup_bucket   = var.backup_bucket
    backup_region   = var.backup_region
    backup_endpoint = var.backup_endpoint
  })

  server_side_apply = true
  wait              = true
}

resource "kubectl_manifest" "pds_configmap" {
  yaml_body = templatefile("${path.module}/pds-configmap.yaml", {
    namespace              = kubernetes_namespace.pds.metadata[0].name
    pds_hostname           = local.pds_hostname
    pds_blobstore_bucket   = var.pds_blobstore_bucket
    pds_blobstore_region   = var.backup_region
    pds_blobstore_endpoint = var.backup_endpoint
  })

  server_side_apply = true
  wait              = true
}

resource "kubectl_manifest" "pds_secret" {
  yaml_body = templatefile("${path.module}/pds-secret.yaml", {
    namespace                = kubernetes_namespace.pds.metadata[0].name
    pds_jwt_secret           = var.pds_jwt_secret
    pds_admin_password       = var.pds_admin_password
    pds_plc_rotation_key     = var.pds_plc_rotation_key
    pds_blobstore_access_key = var.pds_blobstore_access_key
    pds_blobstore_secret_key = var.pds_blobstore_secret_key
  })

  server_side_apply = true
  wait              = true
}

resource "kubectl_manifest" "pds_secret_litestream" {
  yaml_body = templatefile("${path.module}/pds-secret-litestream.yaml", {
    namespace                = kubernetes_namespace.pds.metadata[0].name
    backup_access_key_id     = var.backup_access_key
    backup_secret_access_key = var.backup_secret_key
  })

  server_side_apply = true
  wait              = true
}

resource "kubectl_manifest" "pds_service_headless" {
  yaml_body = templatefile("${path.module}/pds-service-headless.yaml", {
    namespace = kubernetes_namespace.pds.metadata[0].name
  })

  server_side_apply = true
  wait              = true
}

resource "kubectl_manifest" "pds_service" {
  yaml_body = templatefile("${path.module}/pds-service.yaml", {
    namespace = kubernetes_namespace.pds.metadata[0].name
  })

  server_side_apply = true
  wait              = true
}

resource "kubectl_manifest" "pds_ingress" {
  yaml_body = templatefile("${path.module}/pds-ingress.yaml", {
    namespace      = kubernetes_namespace.pds.metadata[0].name
    pds_hostname   = local.pds_hostname
    cluster_domain = var.cluster_domain
  })

  server_side_apply = true
  wait              = true
}

resource "kubectl_manifest" "pds_statefulset" {
  yaml_body = templatefile("${path.module}/pds-statefulset.yaml", {
    namespace        = kubernetes_namespace.pds.metadata[0].name
    pds_version      = local.pds_version
    pds_storage_size = local.pds_storage_size
    backup_bucket    = var.backup_bucket
    backup_endpoint  = var.backup_endpoint
    backup_region    = var.backup_region
  })

  server_side_apply = true
  wait              = true

  depends_on = [
    kubectl_manifest.pds_storageclass,
    kubectl_manifest.pds_configmap,
    kubectl_manifest.pds_secret,
    kubectl_manifest.pds_secret_litestream,
    kubectl_manifest.pds_configmap_litestream
  ]
}

# TODO: Increase storage_size for production workloads
# TODO: Evaluate actual storage needs based on user count
# TODO: Add lifecycle.prevent_destroy for production PVC
# TODO: Production should use 100Gi+ storage, current 10Gi is dev sizing
# TODO: Add pds_email_smtp_url for email verification
# TODO: Add pds_email_from_address for email verification
# TODO: Add pds_repo_signing_key variable (CRITICAL REQUIRED)
# TODO: Add pds_recovery_did_key variable (CRITICAL REQUIRED)
# TODO: Add monitoring/observability integration
# TODO: Add PodDisruptionBudget (single replica limitation)
