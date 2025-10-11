resource "scaleway_iam_application" "ozone" {
  name        = "ozone-db-access"
  description = "IAM application for Ozone database access"
  tags        = var.tags
}

resource "scaleway_iam_api_key" "ozone" {
  application_id = scaleway_iam_application.ozone.id
  description    = "API key for Ozone database access"
}

resource "scaleway_iam_policy" "ozone_db_access" {
  name           = "ozone-db-access"
  description    = "Allow Ozone application to access serverless SQL database"
  application_id = scaleway_iam_application.ozone.id

  rule {
    permission_set_names = ["ServerlessSQLDatabaseReadWrite"]
    project_ids          = [scaleway_sdb_sql_database.ozone.project_id]
  }
}

resource "scaleway_sdb_sql_database" "ozone" {
  name      = var.database_name
  min_cpu   = var.min_cpu_limit
  max_cpu   = var.max_cpu_limit
}

resource "scaleway_container" "ozone" {
  name         = "ozone"
  description  = "Ozone Moderation Service"
  namespace_id = var.namespace_id
  tags         = var.tags

  registry_image = var.registry_image

  port         = var.port
  cpu_limit    = var.cpu_limit
  memory_limit = var.memory_limit
  min_scale    = var.min_scale
  max_scale    = var.max_scale

  privacy  = "public"
  protocol = "http1"
  deploy   = true

  http_option = "redirected"
  # HEALTHCHECK
  environment_variables = merge(
    {
      NODE_ENV              = var.node_env
      LOG_ENABLED           = var.log_enabled
      LOG_LEVEL             = var.log_level
      OZONE_DB_MIGRATE      = var.ozone_db_migrate
      OZONE_PUBLIC_URL      = "https://${var.hostname}"
      OZONE_DID_PLC_URL     = var.ozone_did_plc_url
      OZONE_APPVIEW_URL     = var.ozone_appview_url
      OZONE_APPVIEW_DID     = var.ozone_appview_did
      PLC_DIRECTORY_URL     = var.plc_directory_url
      HANDLE_RESOLVER_URL   = var.handle_resolver_url
      OZONE_SERVER_DID      = var.ozone_server_did
      OZONE_ADMIN_DIDS      = var.ozone_admin_dids
      PGOPTIONS             = "-c search_path=public" # TODO check if this can be removed somehow
    },
    var.environment_variables
  )

  secret_environment_variables = merge(
    {
      OZONE_DB_POSTGRES_URL   = "postgresql://${scaleway_iam_application.ozone.id}:${scaleway_iam_api_key.ozone.secret_key}@${trimsuffix(trimprefix(regex(":\\/\\/.*:", scaleway_sdb_sql_database.ozone.endpoint), "://"), ":")}:5432/${scaleway_sdb_sql_database.ozone.name}?sslmode=require"
      OZONE_ADMIN_PASSWORD    = var.ozone_admin_password
      OZONE_SIGNING_KEY_HEX   = var.ozone_signing_key_hex
    },
    var.secret_environment_variables
  )

  timeouts {
    create = "3m"
  }
}

resource "scaleway_container_domain" "ozone" {
  container_id = scaleway_container.ozone.id
  hostname     = var.hostname

  timeouts {
    create = "3m"
  }
}
