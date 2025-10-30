### Scaleway
region         = "fr-par"
partition      = "prod"
cluster_domain = "eurosky.social"

# Kubernetes
k8s_node_type     = "DEV1-M"
k8s_node_min_size = 1
k8s_node_max_size = 1

# PostgreSQL
postgres_storage_class = "scw-bssd"
# postgres_cluster_name                 = "postgres-wal-gap-recovery-v2"
# postgres_recovery_source_cluster_name = "postgres-wal-gap-test"
# postgres_enable_recovery              = true

# Ozone
ozone_appview_url = "https://api.bsky.app"
ozone_appview_did = "did:web:api.bsky.app"
ozone_server_did  = "did:plc:7kykji2z2jie3tcaz6jypwsf"
ozone_admin_dids  = "did:plc:7kykji2z2jie3tcaz6jypwsf"
ozone_cert_manager_issuer = "letsencrypt-prod"

# PDS
pds_storage_size = "10Gi"
pds_cert_manager_issuer   = "letsencrypt-prod"

# Prometheus
prometheus_storage_class = "scw-bssd"

# Loki
loki_storage_class = "scw-bssd"

# Alertmanager
