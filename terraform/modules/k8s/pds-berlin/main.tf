locals {
  namespace             = "pds-berlin"
  pds_hostname          = "live2025demo.${var.cluster_domain}"
  pds_did_plc_url       = "https://plc.directory"
  pds_bsky_app_view_url = "https://api.bsky.app"
  pds_bsky_app_view_did = "did:web:api.bsky.app"
  pds_mod_service_url   = "https://live2025demo-ozone.eurosky.social"
  pds_mod_service_did   = "did:plc:m4jxet5jry3f5xjxxedu6mt3"
  pds_blob_upload_limit = "52428800"
  pds_log_enabled       = "true"
  pds_storage_size      = "10Gi"


  # System database locations
  pds_data_directory        = "/pds"
  pds_account_db_location   = "${local.pds_data_directory}/account.sqlite"
  pds_sequencer_db_location = "${local.pds_data_directory}/sequencer.sqlite"
  pds_did_cache_db_location = "${local.pds_data_directory}/did_cache.sqlite"
  pds_actor_store_location  = "${local.pds_data_directory}/actors"

  pds_configmap_litestream_yaml = templatefile("${path.module}/pds-configmap-litestream.yaml", {
    namespace                 = kubernetes_namespace.pds.metadata[0].name
    pds_account_db_location   = local.pds_account_db_location
    pds_sequencer_db_location = local.pds_sequencer_db_location
    pds_did_cache_db_location = local.pds_did_cache_db_location
    backup_bucket             = var.backup_bucket
    backup_region             = var.backup_region
    backup_endpoint           = var.backup_endpoint
  })

  pds_configmap_yaml = templatefile("${path.module}/pds-configmap.yaml", {
    namespace                    = kubernetes_namespace.pds.metadata[0].name
    pds_account_db_location      = local.pds_account_db_location
    pds_actor_store_location     = local.pds_actor_store_location
    pds_blob_upload_limit        = local.pds_blob_upload_limit
    pds_blobstore_bucket         = var.pds_blobstore_bucket
    pds_blobstore_endpoint       = var.backup_endpoint
    pds_blobstore_region         = var.backup_region
    pds_bsky_app_view_did        = local.pds_bsky_app_view_did
    pds_bsky_app_view_url        = local.pds_bsky_app_view_url
    pds_data_directory           = local.pds_data_directory
    pds_did_cache_db_location    = local.pds_did_cache_db_location
    pds_did_plc_url              = local.pds_did_plc_url
    pds_email_from_address       = var.pds_email_from_address
    pds_hostname                 = local.pds_hostname
    pds_log_enabled              = local.pds_log_enabled
    pds_mod_service_did          = local.pds_mod_service_did
    pds_mod_service_url          = local.pds_mod_service_url
    pds_moderation_email_address = var.pds_moderation_email_address
    pds_recovery_did_key         = var.pds_recovery_did_key
    pds_sequencer_db_location    = local.pds_sequencer_db_location
  })

  pds_secret_yaml = templatefile("${path.module}/pds-secret.yaml", {
    namespace                     = kubernetes_namespace.pds.metadata[0].name
    pds_jwt_secret                = var.pds_jwt_secret
    pds_admin_password            = var.pds_admin_password
    pds_plc_rotation_key          = var.pds_plc_rotation_key
    pds_dpop_secret               = var.pds_dpop_secret
    pds_blobstore_access_key      = var.pds_blobstore_access_key
    pds_blobstore_secret_key      = var.pds_blobstore_secret_key
    pds_email_smtp_url            = var.pds_email_smtp_url
    pds_moderation_email_smtp_url = var.pds_moderation_email_smtp_url
  })

  pds_secret_litestream_yaml = templatefile("${path.module}/pds-secret-litestream.yaml", {
    namespace                = kubernetes_namespace.pds.metadata[0].name
    backup_access_key_id     = var.backup_access_key
    backup_secret_access_key = var.backup_secret_key
  })

  # Checksums computed from rendered YAML (automatically tracks all changes)
  litestream_config_checksum = sha256(local.pds_configmap_litestream_yaml)
  litestream_secret_checksum = sha256(local.pds_secret_litestream_yaml)
  pds_config_checksum        = sha256(local.pds_configmap_yaml)
  pds_secret_checksum        = sha256(local.pds_secret_yaml)
}

resource "kubernetes_namespace" "pds" {
  metadata {
    name = local.namespace
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
  yaml_body = local.pds_configmap_litestream_yaml

  server_side_apply = true
  wait              = true
}

resource "kubectl_manifest" "pds_configmap" {
  yaml_body = local.pds_configmap_yaml

  server_side_apply = true
  wait              = true
}

resource "kubectl_manifest" "pds_secret" {
  yaml_body = local.pds_secret_yaml

  server_side_apply = true
  wait              = true
}

resource "kubectl_manifest" "pds_secret_litestream" {
  yaml_body = local.pds_secret_litestream_yaml

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
    hostname       = local.pds_hostname
    cluster_domain = var.cluster_domain
  })

  server_side_apply = true
  wait              = true
}

resource "kubectl_manifest" "pds_statefulset" {
  yaml_body = templatefile("${path.module}/pds-statefulset.yaml", {
    namespace                  = kubernetes_namespace.pds.metadata[0].name
    pds_data_directory         = local.pds_data_directory
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
# TODO: Add PDS app metrics + ServiceMonitor
# TODO: Add PodDisruptionBudget (single replica limitation)
# TODO: Investigate how to swap pods with minimal downtime
# TODO: Replace with external secret management solution (Sealed Secrets?)
