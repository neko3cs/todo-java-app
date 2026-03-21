resource "google_cloud_run_service" "app" {
  name     = "todo-app"
  location = var.cloud_run_region

  # Ingress setting is provider-version dependent. The google provider in this environment
  # does not accept a top-level "ingress" argument. Enforce private access via IAM (no allUsers)
  # and Serverless VPC Access connector; verify ingress after deploy and apply ingress via
  # gcloud if needed.

  template {
    spec {
      containers {
        image = "gcr.io/${var.project_id}/todo-app:latest" # placeholder
        env {
          name  = "DATABASE_INSTANCE"
          value = google_sql_database_instance.postgres.connection_name
        }
      }
      container_concurrency = 80
      # Use the terraform-created service account for runtime (ensures consistent invoker principal)
      service_account_name = google_service_account.terraform.email
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }

  autogenerate_revision_name = true

  metadata {
    annotations = {
      "run.googleapis.com/vpc-access-connector" = google_vpc_access_connector.serverless.name
    }
  }
}

resource "google_cloud_run_service_iam_member" "invoker" {
  service = google_cloud_run_service.app.name
  location = google_cloud_run_service.app.location
  role   = "roles/run.invoker"
  # Grant invoker to the terraform service account (used by deployments and operators)
  member = "serviceAccount:${google_service_account.terraform.email}"
}

# Grant the load balancer's service account permission to invoke Cloud Run.
# The LB uses a service account in the format: service-<PROJECT_NUMBER>@gcp-sa-loadbalancing.iam.gserviceaccount.com
data "google_project" "project" {
  project_id = var.project_id
}

resource "google_cloud_run_service_iam_member" "lb_invoker" {
  service  = google_cloud_run_service.app.name
  location = google_cloud_run_service.app.location
  role     = "roles/run.invoker"
  member   = "serviceAccount:service-${data.google_project.project.number}@gcp-sa-loadbalancing.iam.gserviceaccount.com"
}
