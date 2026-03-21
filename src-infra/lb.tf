# Serverless NEG for Cloud Run
resource "google_compute_region_network_endpoint_group" "run_neg" {
  name                  = "run-neg"
  region                = var.region
  network_endpoint_type = "SERVERLESS"

  cloud_run {
    service = google_cloud_run_service.app.name
  }

  depends_on = [google_cloud_run_service.app]
}

# Cloud Armor Security Policy
# NOTE: This policy currently allows only Google health checks and denies all other IPs.
# This is intentionally strict for initial deployment, but for production consider:
# - Attaching Google-managed WAF rule sets (OWASP) using preconfigured WAF rules
# - Adding granular allow rules for expected client CIDRs or known proxy ranges
# - Implementing rate-limiting rules instead of a blanket deny
# DANGER: A blanket deny(403) will block all client traffic. Adjust rules to match desired access model.
resource "google_compute_security_policy" "waf" {
  name = "dev-infra-waf"

  # Allow Google Cloud health checks (required for LB health checks)
  rule {
    priority = 1000
    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = ["130.211.0.0/22","35.191.0.0/16"]
      }
    }
    action = "allow"
  }

  # Default deny for all other traffic - adjust as needed (e.g., allow specific CIDR ranges)
  rule {
    priority = 2000
    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = ["0.0.0.0/0"]
      }
    }
    action = "deny(403)"
  }
}

# Backend service (regional) for Serverless NEG
resource "google_compute_backend_service" "run_backend" {
  name                  = "run-backend"
  protocol              = "HTTP"
  load_balancing_scheme = "EXTERNAL"

  backend {
    group = google_compute_region_network_endpoint_group.run_neg.self_link
  }

  security_policy = google_compute_security_policy.waf.self_link
  depends_on      = [google_compute_region_network_endpoint_group.run_neg]
}

# URL map, target proxy and global forwarding rule (simple HTTP setup)
resource "google_compute_url_map" "url_map" {
  name            = "run-url-map"
  default_service = google_compute_backend_service.run_backend.self_link
}

resource "google_compute_target_http_proxy" "http_proxy" {
  name   = "run-http-proxy"
  url_map = google_compute_url_map.url_map.self_link
}

resource "google_compute_global_forwarding_rule" "http_rule" {
  name       = "run-forwarding-rule"
  ip_protocol = "TCP"
  port_range = "80"
  target     = google_compute_target_http_proxy.http_proxy.self_link
  load_balancing_scheme = "EXTERNAL"
}
