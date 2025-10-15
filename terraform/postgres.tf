# CloudNativePG Operator for PostgreSQL High Availability
# https://cloudnative-pg.io/

resource "helm_release" "cloudnativepg" {
  name      = "cloudnativepg"
  namespace = "cnpg-system"

  create_namespace = true

  repository = "https://cloudnative-pg.github.io/charts"
  chart      = "cloudnative-pg"
  version    = "0.22.1"

  # CloudNativePG operator configuration
  set {
    name  = "monitoring.podMonitorEnabled"
    value = "false"
  }
}

# Namespace for Ozone application and database
resource "kubernetes_namespace" "ozone" {
  metadata {
    name = "ozone"
  }

  depends_on = [helm_release.cloudnativepg]
}

# PostgreSQL Cluster with High Availability
resource "kubectl_manifest" "ozone_postgres_cluster" {
  yaml_body = <<YAML
apiVersion: postgresql.cnpg.io/v1
kind: Cluster
metadata:
  name: ozone-db
  namespace: ${kubernetes_namespace.ozone.metadata[0].name}
spec:
  instances: 3  # HA with 3 replicas

  # PostgreSQL version
  imageName: ghcr.io/cloudnative-pg/postgresql:16.6

  # Storage configuration
  storage:
    storageClass: scw-bssd  # Scaleway Block Storage
    size: 10Gi

  # High Availability configuration
  primaryUpdateStrategy: unsupervised

  # Connection pooling with PgBouncer
  postgresql:
    parameters:
      max_connections: "200"
      shared_buffers: "256MB"
      effective_cache_size: "1GB"
      work_mem: "4MB"

  # Automatic backup configuration (TODO: Add S3 bucket and credentials)
  # backup:
  #   retentionPolicy: "30d"  # 30-day retention per GUIDELINES
  #   barmanObjectStore:
  #     destinationPath: "s3://ozone-db-backups"
  #     s3Credentials:
  #       accessKeyId:
  #         name: backup-s3-creds
  #         key: ACCESS_KEY_ID
  #       secretAccessKey:
  #         name: backup-s3-creds
  #         key: ACCESS_SECRET_KEY
  #     wal:
  #       compression: gzip
  #       maxParallel: 4

  # Bootstrap configuration
  bootstrap:
    initdb:
      database: ozone
      owner: ozone

  # Resource limits
  resources:
    requests:
      memory: "512Mi"
      cpu: "250m"
    limits:
      memory: "1Gi"
      cpu: "1000m"
YAML

  depends_on = [kubernetes_namespace.ozone]
}
