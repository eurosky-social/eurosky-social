locals {
  hostname = "pds.${var.cluster_domain}"
  pds_version      = var.pds_version
  pds_storage_size = var.pds_storage_size

  # ConfigMap/Secret checksums for triggering rolling updates
  pds_config_checksum = sha256(jsonencode({
    pds_hostname           = local.hostname
    pds_blobstore_bucket   = var.pds_blobstore_bucket
    pds_did_plc_url        = var.pds_did_plc_url
    pds_bsky_app_view_url  = var.pds_bsky_app_view_url
    pds_bsky_app_view_did  = var.pds_bsky_app_view_did
    pds_report_service_url = var.pds_report_service_url
    pds_report_service_did = var.pds_report_service_did
    pds_blob_upload_limit  = var.pds_blob_upload_limit
    pds_log_enabled        = var.pds_log_enabled
    pds_email_from_address = var.pds_email_from_address
  }))

  pds_secret_checksum = sha256(jsonencode({
    pds_jwt_secret           = var.pds_jwt_secret
    pds_admin_password       = var.pds_admin_password
    pds_plc_rotation_key     = var.pds_plc_rotation_key
    pds_blobstore_access_key = var.pds_blobstore_access_key
    pds_blobstore_secret_key = var.pds_blobstore_secret_key
    pds_email_smtp_url       = var.pds_email_smtp_url
  }))

  litestream_config_checksum = sha256(jsonencode({
    backup_bucket   = var.backup_bucket
    backup_region   = var.backup_region
    backup_endpoint = var.backup_endpoint
  }))

  litestream_secret_checksum = sha256(jsonencode({
    backup_access_key = var.backup_access_key
    backup_secret_key = var.backup_secret_key
  }))
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
    pds_hostname           = local.hostname
    pds_blobstore_bucket   = var.pds_blobstore_bucket
    pds_blobstore_region   = var.backup_region
    pds_blobstore_endpoint = var.backup_endpoint
    pds_did_plc_url        = var.pds_did_plc_url
    pds_bsky_app_view_url  = var.pds_bsky_app_view_url
    pds_bsky_app_view_did  = var.pds_bsky_app_view_did
    pds_report_service_url = var.pds_report_service_url
    pds_report_service_did = var.pds_report_service_did
    pds_blob_upload_limit  = var.pds_blob_upload_limit
    pds_log_enabled        = var.pds_log_enabled
    pds_email_from_address = var.pds_email_from_address
  })

  server_side_apply = true
  wait              = true
}

resource "kubectl_manifest" "pds_secret" {
  # TODO: Replace with external secret management solution (External Secrets Operator, Sealed Secrets)
  yaml_body = templatefile("${path.module}/pds-secret.yaml", {
    namespace                = kubernetes_namespace.pds.metadata[0].name
    pds_jwt_secret           = var.pds_jwt_secret
    pds_admin_password       = var.pds_admin_password
    pds_plc_rotation_key     = var.pds_plc_rotation_key
    pds_repo_signing_key     = var.pds_repo_signing_key
    pds_blobstore_access_key = var.pds_blobstore_access_key
    pds_blobstore_secret_key = var.pds_blobstore_secret_key
    pds_email_smtp_url       = var.pds_email_smtp_url
  })

  server_side_apply = true
  wait              = true
}

resource "kubectl_manifest" "pds_secret_litestream" {
  # TODO: Replace with external secret management solution (External Secrets Operator, Sealed Secrets)
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
    namespace           = kubernetes_namespace.pds.metadata[0].name
    hostname        = local.hostname
    cluster_domain      = var.cluster_domain
    cert_manager_issuer = var.cert_manager_issuer
  })

  server_side_apply = true
  wait              = true
}

resource "kubectl_manifest" "pds_statefulset" {
  yaml_body = templatefile("${path.module}/pds-statefulset.yaml", {
    namespace                  = kubernetes_namespace.pds.metadata[0].name
    pds_version                = local.pds_version
    pds_storage_size           = local.pds_storage_size
    backup_bucket              = var.backup_bucket
    backup_endpoint            = var.backup_endpoint
    backup_region              = var.backup_region
    pds_config_checksum        = local.pds_config_checksum
    pds_secret_checksum        = local.pds_secret_checksum
    litestream_config_checksum = local.litestream_config_checksum
    litestream_secret_checksum = local.litestream_secret_checksum
  })

  server_side_apply = true
  wait              = true

  lifecycle {
    prevent_destroy = true
  }

  depends_on = [
    kubectl_manifest.pds_storageclass,
    kubectl_manifest.pds_configmap,
    kubectl_manifest.pds_secret,
    kubectl_manifest.pds_secret_litestream,
    kubectl_manifest.pds_configmap_litestream
  ]
}

# TODO: Increase storage_size based on production workloads
# TODO: Add pds_recovery_did_key variable (CRITICAL REQUIRED)
# TODO: Add ServiceMonitor for PDS observability
# TODO: Add PodDisruptionBudget (single replica limitation)
