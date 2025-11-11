# Upcloud
zone                = "de-fra1"
cluster_domain      = "eurosky.social"
k8s_node_plan       = "2xCPU-4GB" # TODO: revisit for prod
partition           = "eurosky"
object_storage_name = "eurosky-data"
k8s_node_count_min  = 2
k8s_node_count_max  = 3

# PostgreSQL
postgres_storage_class = "upcloud-block-storage-standard" # TODO: "upcloud-block-storage-maxiops"
# postgres_cluster_name                 = "postgres-wal-gap-recovery-v2"
# postgres_recovery_source_cluster_name = "postgres-wal-gap-test"
# postgres_enable_recovery              = true

# Ozone
ozone_appview_url = "https://api.bsky.app"
ozone_appview_did = "did:web:api.bsky.app"
ozone_server_did  = "did:plc:7kykji2z2jie3tcaz6jypwsf"

# PDS
pds_storage_size      = "10Gi"
pds_did_plc_url       = "https://plc.directory"
pds_bsky_app_view_url = "https://api.bsky.app"
pds_bsky_app_view_did = "did:web:api.bsky.app"
pds_blob_upload_limit = "52428800"
pds_log_enabled       = "true"

# Prometheus
prometheus_storage_class = "upcloud-block-storage-standard" # TODO: "upcloud-block-storage-maxiops"

# Loki
loki_storage_class = "upcloud-block-storage-standard" # TODO: "upcloud-block-storage-maxiops"

# Relay
relay_storage_class = "upcloud-block-storage-standard"
relay_storage_size  = "90Gi"