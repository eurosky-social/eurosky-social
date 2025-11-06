locals {
  hostname = "user.${var.cluster_domain}"

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
    pds_hostname                 = local.hostname
    pds_data_directory           = local.pds_data_directory
    pds_account_db_location      = local.pds_account_db_location
    pds_sequencer_db_location    = local.pds_sequencer_db_location
    pds_did_cache_db_location    = local.pds_did_cache_db_location
    pds_actor_store_location     = local.pds_actor_store_location
    pds_blobstore_bucket         = var.pds_blobstore_bucket
    pds_blobstore_region         = var.backup_region
    pds_blobstore_endpoint       = var.backup_endpoint
    pds_did_plc_url              = var.pds_did_plc_url
    pds_bsky_app_view_url        = var.pds_bsky_app_view_url
    pds_bsky_app_view_did        = var.pds_bsky_app_view_did
    pds_mod_service_url          = var.pds_mod_service_url
    pds_mod_service_did          = var.pds_mod_service_did
    pds_blob_upload_limit        = var.pds_blob_upload_limit
    pds_log_enabled              = var.pds_log_enabled
    pds_email_from_address       = var.pds_email_from_address
    pds_moderation_email_address = var.pds_moderation_email_address
    pds_recovery_did_key         = var.pds_recovery_did_key
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
    namespace           = kubernetes_namespace.pds.metadata[0].name
    hostname            = local.hostname
    cluster_domain      = var.cluster_domain
    cert_manager_issuer = var.cert_manager_issuer
  })

  server_side_apply = true
  wait              = true
}

resource "kubectl_manifest" "pds_statefulset" {
  yaml_body = templatefile("${path.module}/pds-statefulset.yaml", {
    namespace                  = kubernetes_namespace.pds.metadata[0].name
    pds_data_directory         = local.pds_data_directory
    pds_storage_size           = var.pds_storage_size
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