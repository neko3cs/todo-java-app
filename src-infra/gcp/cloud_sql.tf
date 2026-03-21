# Reserved range for private services access (VPC peering for Cloud SQL private IP)
resource "google_compute_global_address" "private_services_access" {
  name          = "private-services-${var.project_id}"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.default.id
}

resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = google_compute_network.default.self_link
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_services_access.name]
  # The `project` argument is provider-version dependent and may not be accepted; provider will infer project from
  # the provider configuration. Omit `project` for broader compatibility.
}

resource "google_sql_database_instance" "postgres" {
  name             = var.sql_instance_name
  database_version = "POSTGRES_17"
  region           = var.region

  settings {
    tier = var.sql_tier
    ip_configuration {
      ipv4_enabled    = false
      private_network = google_compute_network.default.self_link
    }
  }

  deletion_protection = false
}
