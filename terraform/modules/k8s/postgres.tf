locals {
  postgres_cluster_name   = "postgres-cluster"
  postgres_ca_secret_name = "${local.postgres_cluster_name}-ca"
}

resource "helm_release" "cloudnativepg" {
  name      = "cloudnativepg"
  namespace = "cnpg-system"

  create_namespace = true

  repository = "https://cloudnative-pg.github.io/charts"
  chart      = "cloudnative-pg"
  version    = "0.26.0" # TODO: Verify latest stable version and pin with constraints

  set {
    name  = "monitoring.podMonitorEnabled"
    value = "false" # TODO: Enable monitoring.podMonitorEnabled when Prometheus is deployed
  }
}

data "http" "barman_cloud_plugin_manifest" {
  url = "https://github.com/cloudnative-pg/plugin-barman-cloud/releases/download/v0.7.0/manifest.yaml" # TODO: Pin to specific version and verify latest release
}

data "kubectl_file_documents" "barman_cloud_plugin_docs" {
  content = data.http.barman_cloud_plugin_manifest.response_body
}

resource "kubectl_manifest" "barman_cloud_plugin" {
  for_each = data.kubectl_file_documents.barman_cloud_plugin_docs.manifests

  yaml_body         = each.value
  server_side_apply = true
  wait              = true

  depends_on = [
    null_resource.wait_for_cert_manager_webhook,
    helm_release.cloudnativepg
  ]
}

resource "kubernetes_namespace" "databases" {
  metadata {
    name = "databases"
  }
}

resource "kubernetes_secret" "backup_s3_creds" {
  metadata {
    name      = "backup-s3-creds"
    namespace = kubernetes_namespace.databases.metadata[0].name
  }

  data = {
    ACCESS_KEY_ID     = var.backup_s3_access_key
    ACCESS_SECRET_KEY = var.backup_s3_secret_key
  }

  type = "Opaque"

  lifecycle {
    ignore_changes = [data]
  }
}

resource "kubernetes_secret" "ozone_db" {
  metadata {
    name      = "ozone-db-secret"
    namespace = kubernetes_namespace.databases.metadata[0].name

    labels = {
      "cnpg.io/reload" = "true"
    }
  }

  data = {
    username = "ozone_user"
    password = var.ozone_db_password
  }

  type = "kubernetes.io/basic-auth"
}

resource "kubectl_manifest" "postgres_rbac" {
  yaml_body = templatefile("${path.module}/postgres-rbac.yaml", {
    namespace    = kubernetes_namespace.databases.metadata[0].name
    secret_name  = kubernetes_secret.backup_s3_creds.metadata[0].name
    cluster_name = local.postgres_cluster_name
  })

  server_side_apply = true
  wait              = true
}

resource "kubectl_manifest" "postgres_backup_objectstore" {
  yaml_body = templatefile("${path.module}/postgres-backup-objectstore.yaml", {
    namespace        = kubernetes_namespace.databases.metadata[0].name
    destination_path = "s3://${var.backup_s3_bucket}/postgres/"
    endpoint_url     = var.backup_s3_endpoint
    secret_name      = kubernetes_secret.backup_s3_creds.metadata[0].name
  })

  server_side_apply = true
  wait              = true

  depends_on = [
    kubectl_manifest.barman_cloud_plugin
  ]
}

resource "kubectl_manifest" "postgres_cluster" {
  yaml_body = templatefile("${path.module}/postgres-cluster.yaml", {
    namespace     = kubernetes_secret.ozone_db.metadata[0].namespace
    cluster_name  = local.postgres_cluster_name
    storage_class = var.backup_storage_class
  })

  server_side_apply = true
  wait              = true

  depends_on = [
    helm_release.cloudnativepg,
    kubectl_manifest.postgres_backup_objectstore
  ]
}

resource "kubectl_manifest" "postgres_scheduled_backup" { # TODO: Add retentionPolicy parameter ('30d' or '60d' recommended for production)
  yaml_body = templatefile("${path.module}/postgres-scheduled-backup.yaml", {
    namespace    = kubernetes_secret.ozone_db.metadata[0].namespace
    cluster_name = kubectl_manifest.postgres_cluster.name
  })

  server_side_apply = true
  wait              = true
}

resource "kubectl_manifest" "postgres_ozone_database" {
  yaml_body = templatefile("${path.module}/postgres-database.yaml", {
    namespace    = kubernetes_secret.ozone_db.metadata[0].namespace
    cluster_name = local.postgres_cluster_name
  })

  server_side_apply = true
  wait              = true

  depends_on = [
    kubectl_manifest.postgres_cluster,
    kubernetes_secret.ozone_db
  ]
}

# TODO: Enable CloudNativePG Pooler for connection pooling (PgBouncer with PoolerType 'rw')
# TODO: Configure Pooler HPA for autoscaling based on CPU/connection metrics
# TODO: Add PodDisruptionBudget for postgres-cluster to ensure HA during node maintenance
# TODO: Implement backup verification job to test restore procedures monthly
# TODO: Add alerts for backup failures, replication lag, and disk usage
# TODO: Document connection string format for applications (use pooler endpoint)
# TODO: Configure backup encryption at rest using ObjectStore encryption settings
