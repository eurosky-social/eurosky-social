locals {
  postgres_ca_secret_name = "${var.postgres_cluster_name}-ca"
  pooler_name             = "postgres-pooler-rw"

  # Backup configuration (single ObjectStore for both backup and recovery)
  backup_objectstore_name = "postgres-backup-s3"
}

resource "helm_release" "cloudnativepg" {
  name      = "cloudnativepg"
  namespace = "cnpg-system"

  create_namespace = true

  repository = "https://cloudnative-pg.github.io/charts"
  chart      = "cloudnative-pg"
  version    = var.cnpg_version

  set {
    name  = "monitoring.podMonitorEnabled"
    value = true
  }
}

resource "helm_release" "barman_cloud_plugin" {
  name      = "plugin-barman-cloud"
  namespace = "cnpg-system"

  repository = "https://cloudnative-pg.github.io/charts"
  chart      = "plugin-barman-cloud"
  version    = var.barman_plugin_chart_version

  depends_on = [helm_release.cloudnativepg]
}

resource "kubernetes_namespace" "databases" {
  metadata {
    name = var.namespace
  }
}

resource "kubernetes_secret" "backup_s3_creds" {
  metadata {
    name      = "backup-s3-creds"
    namespace = kubernetes_namespace.databases.metadata[0].name

    labels = {
      "cnpg.io/reload" = "true"
    }
  }

  data = {
    ACCESS_KEY_ID     = var.backup_s3_access_key
    ACCESS_SECRET_KEY = var.backup_s3_secret_key
  }

  type = "Opaque"
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
    cluster_name = var.postgres_cluster_name
  })

  server_side_apply = true
  wait              = true
}

resource "kubectl_manifest" "postgres_backup_objectstore" {
  yaml_body = templatefile("${path.module}/postgres-backup-objectstore.yaml", {
    objectstore_name = local.backup_objectstore_name
    namespace        = kubernetes_namespace.databases.metadata[0].name
    destination_path = "s3://${var.backup_s3_bucket}/postgres/"
    endpoint_url     = var.backup_s3_endpoint
    secret_name      = kubernetes_secret.backup_s3_creds.metadata[0].name
    s3_region        = var.backup_s3_region
  })

  server_side_apply = true
  wait              = true

  depends_on = [helm_release.barman_cloud_plugin]
}

resource "kubectl_manifest" "postgres_cluster" {
  yaml_body = templatefile("${path.module}/postgres-cluster.yaml", {
    namespace                    = kubernetes_secret.ozone_db.metadata[0].namespace
    cluster_name                 = var.postgres_cluster_name
    storage_class                = var.storage_class
    backup_objectstore_name      = local.backup_objectstore_name
    recovery_source_cluster_name = var.recovery_source_cluster_name
    enable_recovery              = var.enable_recovery
    archive_timeout              = var.archive_timeout
  })

  server_side_apply = true
  wait              = true

  depends_on = [
    helm_release.cloudnativepg,
    kubectl_manifest.postgres_backup_objectstore
  ]
}

resource "kubectl_manifest" "postgres_scheduled_backup" {
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
    cluster_name = var.postgres_cluster_name
  })

  server_side_apply = true
  wait              = true

  depends_on = [
    kubectl_manifest.postgres_cluster,
    kubernetes_secret.ozone_db
  ]
}

resource "kubectl_manifest" "postgres_pooler" {
  yaml_body = templatefile("${path.module}/postgres-pooler.yaml", {
    pooler_name  = local.pooler_name
    namespace    = kubernetes_namespace.databases.metadata[0].name
    cluster_name = var.postgres_cluster_name
  })

  server_side_apply = true
  wait              = true

  depends_on = [kubectl_manifest.postgres_cluster]
}
# TODO: Configure Pooler HPA for autoscaling based on CPU/connection metrics
# TODO: Add PodDisruptionBudget for postgres-cluster to ensure HA during node maintenance
# TODO: Implement backup verification job to test restore procedures monthly
# TODO: Add alerts for backup failures, replication lag, and disk usage
# TODO: Document connection string format for applications (use pooler endpoint)
# TODO: Configure backup encryption at rest using ObjectStore encryption settings
# TODO: https://cloudnative-pg.io/documentation/current/monitoring/
# TODO: add an healthcheck watchdog for backups