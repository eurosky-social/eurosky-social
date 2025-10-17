# # ObjectStore resource for Barman Cloud Plugin (CNPG-I architecture)
# resource "kubectl_manifest" "postgres_backup_objectstore" {
#   yaml_body = <<YAML
# apiVersion: barmancloud.cnpg.io/v1
# kind: ObjectStore
# metadata:
#   name: postgres-backup-s3
#   namespace: ${kubernetes_namespace.databases.metadata[0].name}
# spec:
#   configuration:
#     destinationPath: "s3://${scaleway_object_bucket.postgres_backups.name}/backups"
#     endpointURL: "https://s3.${var.region}.scw.cloud"
#     s3Credentials:
#       accessKeyId:
#         name: ${kubernetes_secret.postgres_backup_s3.metadata[0].name}
#         key: ACCESS_KEY_ID
#       secretAccessKey:
#         name: ${kubernetes_secret.postgres_backup_s3.metadata[0].name}
#         key: ACCESS_SECRET_KEY
#     wal:
#       compression: gzip
#       maxParallel: 4
# YAML

#   depends_on = [
#     helm_release.barman_cloud_plugin,
#   ]
# }
