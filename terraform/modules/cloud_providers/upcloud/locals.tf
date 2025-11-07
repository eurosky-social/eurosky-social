locals {
  ingress_nginx_extra_annotations = {
    # UpCloud LoadBalancer config: HTTP mode for client IP preservation and automatic TLS
    # Requires one-time ACME challenge CNAME in DNS for wildcard domains
    "service.beta.kubernetes.io/upcloud-load-balancer-config" = jsonencode({
      networks = [
        {
          name   = "public"
          type   = "public"
          family = "IPv4"
        },
        {
          name   = "${var.partition}-net"
          type   = "private"
          family = "IPv4"
          uuid   = upcloud_network.main.id
        }
      ]
      frontends = [
        {
          name            = "http"
          mode            = "http"
          port            = 80
          default_backend = "http"
          networks = [
            {
              name = "public"
            }
          ]
          rules = [
            {
              name     = "redirect-to-https"
              priority = 100
              matchers = []
              actions = [
                {
                  type = "http_redirect"
                  action_http_redirect = {
                    scheme = "https"
                    status = 301
                  }
                }
              ]
            }
          ]
        },
        {
          name            = "https"
          mode            = "http"
          port            = 443
          default_backend = "http"
          networks = [
            {
              name = "public"
            }
          ]
          tls_configs = [
            {
              name                    = "auto-tls"
              certificate_bundle_uuid = upcloud_loadbalancer_dynamic_certificate_bundle.ingress.id
            }
          ]
          rules = [
            {
              name     = "set-forwarded-headers"
              priority = 100
              matchers = []
              actions = [
                {
                  type                         = "set_forwarded_headers"
                  action_set_forwarded_headers = {}
                }
              ]
            }
          ]
        }
      ]
      backends = [
        {
          name       = "http"
          properties = {}
        }
      ]
    })
  }
}

# TODO: find out how to set HSTS
