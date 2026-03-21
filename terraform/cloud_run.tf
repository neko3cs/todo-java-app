# Cloud Run service (internal ingress)
resource "google_cloud_run_service" "app" {
  name     = var.cloud_run_service_name
  location = var.region

  template {
    metadata {
      annotations = {
        # Restrict direct public ingress; allow Cloud Load Balancers to reach service
        "run.googleapis.com/ingress" = "internal-and-cloud-load-balancers"
      }
    }

    spec {
      containers {
        image = var.cloud_run_image

        env {
          name  = "DB_INSTANCE_CONNECTION_NAME"
          value = google_sql_database_instance.postgres.connection_name
        }
      }
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }

  depends_on = [google_project_service.enabled]
}

# Allow Cloud Run invocation from specified service account (set via var.lb_invoker_sa). Leave empty to skip.
resource "google_cloud_run_service_iam_member" "invoker" {
  count    = var.lb_invoker_sa != "" ? 1 : 0
  service  = google_cloud_run_service.app.name
  location = google_cloud_run_service.app.location
  role     = "roles/run.invoker"
  member   = var.lb_invoker_sa
}
