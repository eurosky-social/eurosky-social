resource "helm_release" "cloudnativepg" {
  name      = "cloudnativepg"
  namespace = "cnpg-system"

  create_namespace = true

  repository = "https://cloudnative-pg.github.io/charts"
  chart      = "cloudnative-pg"
  version    = "0.26.0"

  set {
    name  = "monitoring.podMonitorEnabled"
    value = "false"
  }
}

data "http" "barman_cloud_plugin_manifest" {
  url = "https://github.com/cloudnative-pg/plugin-barman-cloud/releases/download/v0.7.0/manifest.yaml"
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
    helm_release.cert_manager,
    helm_release.cloudnativepg
  ]
}

resource "kubernetes_namespace" "databases" {
  metadata {
    name = "databases"
  }
}

resource "kubernetes_secret" "postgres_backup_s3" {
  metadata {
    name      = "postgres-backup-s3-creds"
    namespace = kubernetes_namespace.databases.metadata[0].name
  }

  data = {
    ACCESS_KEY_ID     = var.postgres_backup_access_key
    ACCESS_SECRET_KEY = var.postgres_backup_secret_key
  }

  type = "Opaque"
}

resource "random_password" "ozone_db_password" {
  length  = 32
  special = true
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
    password = random_password.ozone_db_password.result
  }

  type = "kubernetes.io/basic-auth"
}

resource "kubectl_manifest" "postgres_rbac" {
  yaml_body = templatefile("${path.module}/postgres-rbac.yaml", {
    namespace   = kubernetes_namespace.databases.metadata[0].name
    secret_name = kubernetes_secret.postgres_backup_s3.metadata[0].name
  })

  server_side_apply = true
  wait              = true
}

resource "kubectl_manifest" "postgres_backup_objectstore" {
  yaml_body = templatefile("${path.module}/postgres-backup-objectstore.yaml", {
    namespace        = kubernetes_namespace.databases.metadata[0].name
    destination_path = var.postgres_backup_destination_path
    endpoint_url     = var.postgres_backup_endpoint_url
    secret_name      = kubernetes_secret.postgres_backup_s3.metadata[0].name
  })

  server_side_apply = true
  wait              = true

  depends_on = [
    kubectl_manifest.barman_cloud_plugin
  ]
}

resource "kubectl_manifest" "postgres_cluster" {
  yaml_body = templatefile("${path.module}/postgres-cluster.yaml", {
    namespace     = kubernetes_namespace.databases.metadata[0].name
    storage_class = var.postgres_storage_class
  })

  server_side_apply = true
  wait              = true

  depends_on = [
    helm_release.cloudnativepg,
    kubectl_manifest.postgres_rbac,
    kubectl_manifest.postgres_backup_objectstore
  ]
}

resource "kubectl_manifest" "postgres_scheduled_backup" {
  yaml_body = templatefile("${path.module}/postgres-scheduled-backup.yaml", {
    namespace = kubernetes_namespace.databases.metadata[0].name
  })

  server_side_apply = true
  wait              = true

  depends_on = [
    kubectl_manifest.postgres_cluster
  ]
}
