locals {
  relay_data_directory = "/data/relay"
  relay_db_path        = "${local.relay_data_directory}/relay.sqlite"
  relay_persist_dir    = "${local.relay_data_directory}/persist"

  relay_configmap_yaml = templatefile("${path.module}/relay-configmap.yaml", {
    namespace         = kubernetes_namespace.relay.metadata[0].name
    relay_db_path     = local.relay_db_path
    relay_persist_dir = local.relay_persist_dir
  })

  relay_secret_yaml = templatefile("${path.module}/relay-secret.yaml", {
    namespace            = kubernetes_namespace.relay.metadata[0].name
    relay_admin_password = var.relay_admin_password
  })

  relay_configmap_litestream_yaml = templatefile("${path.module}/relay-configmap-litestream.yaml", {
    namespace       = kubernetes_namespace.relay.metadata[0].name
    relay_db_path   = local.relay_db_path
    backup_bucket   = var.backup_bucket
    backup_region   = var.backup_region
    backup_endpoint = var.backup_endpoint
  })

  relay_secret_litestream_yaml = templatefile("${path.module}/relay-secret-litestream.yaml", {
    namespace         = kubernetes_namespace.relay.metadata[0].name
    backup_access_key = var.backup_access_key
    backup_secret_key = var.backup_secret_key
  })

  # Checksums computed from rendered YAML (automatically tracks all changes)
  relay_config_checksum      = sha256(local.relay_configmap_yaml)
  relay_secret_checksum      = sha256(local.relay_secret_yaml)
  litestream_config_checksum = sha256(local.relay_configmap_litestream_yaml)
  litestream_secret_checksum = sha256(local.relay_secret_litestream_yaml)
}

resource "kubernetes_namespace" "relay" {
  metadata {
    name = "relay"
  }
}

resource "kubectl_manifest" "relay_configmap" {
  yaml_body = local.relay_configmap_yaml

  server_side_apply = true
  wait              = true
}

resource "kubectl_manifest" "relay_secret" {
  yaml_body = local.relay_secret_yaml

  server_side_apply = true
  wait              = true
}

resource "kubectl_manifest" "relay_configmap_litestream" {
  yaml_body = local.relay_configmap_litestream_yaml

  server_side_apply = true
  wait              = true
}

resource "kubectl_manifest" "relay_secret_litestream" {
  yaml_body = local.relay_secret_litestream_yaml

  server_side_apply = true
  wait              = true
}

resource "kubectl_manifest" "relay_service" {
  yaml_body = templatefile("${path.module}/relay-service.yaml", {
    namespace = kubernetes_namespace.relay.metadata[0].name
  })

  server_side_apply = true
  wait              = true
}

resource "kubectl_manifest" "relay_servicemonitor" {
  yaml_body = templatefile("${path.module}/relay-servicemonitor.yaml", {
    namespace = kubernetes_namespace.relay.metadata[0].name
  })

  server_side_apply = true
  wait              = true
}

resource "kubectl_manifest" "relay_ingress" {
  yaml_body = templatefile("${path.module}/relay-ingress.yaml", {
    namespace      = kubernetes_namespace.relay.metadata[0].name
    hostname       = "relay.${var.cluster_domain}"
    cluster_domain = var.cluster_domain
  })

  server_side_apply = true
  wait              = true

  depends_on = [
    kubectl_manifest.relay_service
  ]
}


resource "kubectl_manifest" "relay_configmap_sync_script" {
  yaml_body = templatefile("${path.module}/relay-configmap-sync-script.yaml", {
    namespace   = kubernetes_namespace.relay.metadata[0].name
    sync_script = file("${path.module}/scripts/sync-hosts.sh")
  })

  server_side_apply = true
  wait              = true
}

resource "kubectl_manifest" "relay_cronjob_sync_hosts" {
  yaml_body = templatefile("${path.module}/relay-cronjob-sync-hosts.yaml", {
    namespace = kubernetes_namespace.relay.metadata[0].name
  })

  server_side_apply = true
  wait              = true

  depends_on = [
    kubectl_manifest.relay_configmap_sync_script,
    kubectl_manifest.relay_secret
  ]
}

resource "kubectl_manifest" "relay_statefulset" {
  yaml_body = templatefile("${path.module}/relay-statefulset.yaml", {
    namespace                  = kubernetes_namespace.relay.metadata[0].name
    relay_data_directory       = local.relay_data_directory
    relay_storage_class        = var.relay_storage_class
    relay_storage_size         = var.relay_storage_size
    relay_config_checksum      = local.relay_config_checksum
    relay_secret_checksum      = local.relay_secret_checksum
    litestream_config_checksum = local.litestream_config_checksum
    litestream_secret_checksum = local.litestream_secret_checksum
  })

  server_side_apply = true
  wait              = true

  lifecycle {
    prevent_destroy = true
  }

  depends_on = [
    kubectl_manifest.relay_configmap,
    kubectl_manifest.relay_secret,
    kubectl_manifest.relay_configmap_litestream,
    kubectl_manifest.relay_secret_litestream,
    kubectl_manifest.relay_configmap_sync_script,
    kubectl_manifest.relay_service
  ]
}
