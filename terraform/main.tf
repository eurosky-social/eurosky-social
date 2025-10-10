resource scaleway_container_namespace main {
  name = "serverless-example-ns"
  description = "Namespace managed by terraform"
}

resource scaleway_container main {
  name = "serverless-example-container"
  description = "NGINX container deployed with terraform"
  namespace_id = scaleway_container_namespace.main.id
  registry_image = "docker.io/library/nginx:latest"
  port = 80
  cpu_limit = 1000
  memory_limit = 1028
  min_scale = 0
  max_scale = 1
  privacy = "public"
  protocol = "http1"
  deploy = true
  http_option = "redirected"
}

resource scaleway_container_domain main {
  container_id = scaleway_container.main.id
  hostname     = var.hostname
}
