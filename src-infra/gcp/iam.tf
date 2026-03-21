resource "google_service_account" "terraform" {
  account_id   = "todo-terraform-sa"
  display_name = "Terraform service account for todo infra"
}

# Example minimal role bindings - review and minimize as needed
resource "google_project_iam_member" "sa_cloudsql_client" {
  project = var.project_id
  role    = "roles/cloudsql.client"
  member  = "serviceAccount:${google_service_account.terraform.email}"
}

# Grant Cloud Run Admin only to the service account (scope minimized)
resource "google_project_iam_member" "sa_run_admin" {
  project = var.project_id
  role    = "roles/run.admin"
  member  = "serviceAccount:${google_service_account.terraform.email}"
}

# Replace broad compute.admin with compute.networkAdmin and compute.securityAdmin where possible.
# compute.networkAdmin is sufficient for creating forwarding rules, backend services, and NEG resources.
resource "google_project_iam_member" "sa_compute_network_admin" {
  project = var.project_id
  role    = "roles/compute.networkAdmin"
  member  = "serviceAccount:${google_service_account.terraform.email}"
}

# Grant security-related compute permissions for Cloud Armor/security policy management
resource "google_project_iam_member" "sa_compute_security_admin" {
  project = var.project_id
  role    = "roles/compute.securityAdmin"
  member  = "serviceAccount:${google_service_account.terraform.email}"
}
