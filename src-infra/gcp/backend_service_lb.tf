# Backend service using Serverless NEG
resource "google_compute_backend_service" "todo_backend" {
  name                     = "todo-backend"
  protocol                 = "HTTP"
  load_balancing_scheme    = "EXTERNAL"
  enable_cdn               = false
  port_name                = "http"
  timeout_sec              = 30

  # Attach Cloud Armor policy by referencing its self_link/name where supported by the provider
  security_policy = try(google_compute_security_policy.waf_policy.self_link, google_compute_security_policy.waf_policy.name)

  # Attach NEG
  backend {
    group = google_compute_region_network_endpoint_group.serverless_neg.id
  }
}

resource "google_compute_url_map" "todo_map" {
  name = "todo-url-map"

  default_service = google_compute_backend_service.todo_backend.self_link
}

resource "google_compute_target_http_proxy" "http_proxy" {
  name   = "todo-http-proxy"
  url_map = google_compute_url_map.todo_map.self_link
}

resource "google_compute_global_forwarding_rule" "http_forward" {
  name       = "todo-forwarding-rule"
  target     = google_compute_target_http_proxy.http_proxy.self_link
  port_range = "80"
  ip_protocol = "TCP"
}
