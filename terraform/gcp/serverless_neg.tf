resource "google_compute_region_network_endpoint_group" "serverless_neg" {
  name                  = "todo-serverless-neg"
  region                = var.cloud_run_region
  project               = var.project_id
  network_endpoint_type = "SERVERLESS"

  cloud_run {
    service = google_cloud_run_service.app.name
    tag     = ""
  }
}
