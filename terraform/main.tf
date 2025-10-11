resource scaleway_container_namespace main {
  name = "main"
  description = "Main namespace managed by terraform"
}


module "ozone" {
  source = "./modules/ozone"

  namespace_id   = scaleway_container_namespace.main.id
  hostname       = var.ozone_hostname
  registry_image = "ghcr.io/eurosky-social/ozone:latest"

  cpu_limit    = 2000
  memory_limit = 2048
  min_scale    = 0
  max_scale    = 5

  # Required Ozone URLs - Update these for production
  ozone_did_plc_url     = "https://plc.directory"  # TODO: Update with your PLC URL
  ozone_appview_url     = "https://bsky.app"       # TODO: Update with your AppView URL
  ozone_appview_did     = "did:web:bsky.app"       # TODO: Update with your AppView DID
  plc_directory_url     = "https://plc.directory"  # TODO: Update with your PLC directory URL
  handle_resolver_url   = "https://bsky.app"       # TODO: Update with your handle resolver URL

  # Required secrets - MUST be updated for production
  ozone_admin_password  = "CHANGE_ME_ADMIN_PASSWORD"  # TODO: Generate secure password
  ozone_signing_key_hex = "da7a7d92e8d8f8e6f2a5a1b8c4d3e2f1a9b7c5d4e3f2a8b6c9d7e5f3a1b4c6d8"  # TODO: Generate new signing key

  # Required DIDs - MUST be updated for production
  ozone_server_did = "did:plc:CHANGEME"              # TODO: Set Ozone server DID
  ozone_admin_dids = "did:plc:CHANGEME1,did:plc:CHANGEME2"  # TODO: Set admin DIDs (comma-separated)

  # Additional environment variables
  environment_variables = {
    # Add your production environment variables here
  }

  secret_environment_variables = {
    # Add your secret environment variables here
  }
}
