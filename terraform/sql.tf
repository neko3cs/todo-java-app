# Cloud SQL (Postgres 17) with Private IP
resource "google_sql_database_instance" "postgres" {
  name             = var.db_instance_name
  database_version = "POSTGRES_17"
  region           = var.region

  settings {
    tier            = var.db_tier
    disk_autoresize = true

    # Prefer regional availability for high availability
    availability_type = "REGIONAL"

    # Enable automated backups for point-in-time restore
    backup_configuration {
      enabled    = true
      start_time = "03:00"
    }

    ip_configuration {
      ipv4_enabled    = false
      private_network = google_compute_network.main.self_link
    }
  }

  # Prevent accidental deletion in non-experimental environments
  deletion_protection = true

  depends_on = [google_service_networking_connection.private_vpc, google_project_service.enabled]
}

resource "google_sql_database" "appdb" {
  name     = "appdb"
  instance = google_sql_database_instance.postgres.name
}
