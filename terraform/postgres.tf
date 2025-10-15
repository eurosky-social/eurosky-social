# CloudNativePG Operator for PostgreSQL High Availability
# https://cloudnative-pg.io/

resource "helm_release" "cloudnativepg" {
  name      = "cloudnativepg"
  namespace = "cnpg-system"

  create_namespace = true

  repository = "https://cloudnative-pg.github.io/charts"
  chart      = "cloudnative-pg"
  version    = "0.26.0"

  # CloudNativePG operator configuration
  set {
    name  = "monitoring.podMonitorEnabled"
    value = "false"
  }
}

resource "helm_release" "barman_cloud_plugin" {
  name      = "barman-cloud"
  namespace = "cnpg-system"

  repository = "https://cloudnative-pg.github.io/charts"
  chart      = "plugin-barman-cloud"
  version    = "0.2.0"

  depends_on = [helm_release.cloudnativepg]
}

resource "kubernetes_namespace" "databases" {
  metadata {
    name = "databases"
  }

  depends_on = [helm_release.cloudnativepg]
}

resource "kubectl_manifest" "postgres_cluster" {
  yaml_body = <<YAML
apiVersion: postgresql.cnpg.io/v1
kind: Cluster
metadata:
  name: postgres-cluster
  namespace: ${kubernetes_namespace.databases.metadata[0].name}
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

  topologySpreadConstraints:
    - maxSkew: 1
      topologyKey: topology.kubernetes.io/zone
      whenUnsatisfiable: DoNotSchedule
      labelSelector:
        matchLabels:
          cnpg.io/cluster: postgres-cluster

  affinity:
    podAntiAffinityType: required
    topologyKey: kubernetes.io/hostname

  # Connection pooling with PgBouncer
  postgresql:
    parameters:
      max_connections: "200"
      shared_buffers: "256MB"
      effective_cache_size: "1GB"
      work_mem: "4MB"
      wal_compression: "on"  # Compress WAL before archiving
      archive_timeout: "1h"  # Archive every 1 hour OR when segment full (16MB)

  # Plugin-based backup configuration (CNPG-I architecture)
  plugins:
    - name: barman-cloud.cloudnative-pg.io
      parameters:
        barmanObjectName: postgres-backup-s3

  # Bootstrap configuration
  bootstrap:
    initdb:
      database: app
      owner: app

  # Resource limits
  resources:
    requests:
      memory: "512Mi"
      cpu: "250m"
    limits:
      memory: "1Gi"
      cpu: "1000m"
YAML
}
