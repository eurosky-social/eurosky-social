# # Daily backup schedule (2 AM UTC) using plugin architecture
# resource "kubectl_manifest" "postgres_daily_backup" {
#   yaml_body = <<YAML
# apiVersion: postgresql.cnpg.io/v1
# kind: ScheduledBackup
# metadata:
#   name: postgres-daily-backup
#   namespace: ${kubernetes_namespace.databases.metadata[0].name}
# spec:
#   schedule: "0 2 * * *"  # Daily at 2 AM UTC
#   backupOwnerReference: self
#   cluster:
#     name: postgres-cluster
#   method: plugin
#   pluginConfiguration:
#     name: barman-cloud.cloudnative-pg.io
#   immediate: false
# YAML

#   depends_on = [
#     kubectl_manifest.postgres_cluster,
#     kubectl_manifest.postgres_backup_objectstore
#   ]
# }
