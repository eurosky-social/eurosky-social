resource scaleway_container_namespace main {
  name = "main"
  description = "Main namespace managed by terraform"
}


module "ozone" {
  source = "./modules/ozone"

  namespace_id   = scaleway_container_namespace.main.id
  hostname       = var.ozone_hostname
  registry_image = "ghcr.io/eurosky-social/ozone:latest"

  min_scale    = 0
  max_scale    = 5

  ozone_did_plc_url     = var.ozone_did_plc_url
  ozone_appview_url     = var.ozone_appview_url
  ozone_appview_did     = var.ozone_appview_did
  plc_directory_url     = var.plc_directory_url
  handle_resolver_url   = var.handle_resolver_url
  ozone_admin_password  = var.ozone_admin_password
  ozone_signing_key_hex = var.ozone_signing_key_hex
  ozone_server_did = var.ozone_server_did
  ozone_admin_dids = var.ozone_admin_dids

  # Additional environment variables
  environment_variables = {
    # Add your production environment variables here
  }

  secret_environment_variables = {
    # Add your secret environment variables here
  }
}
