output "cloud_run_service" {
  description = "Cloud Run service name"
  value       = google_cloud_run_service.app.name
}

output "cloud_sql_instance" {
  description = "Cloud SQL instance name"
  value       = google_sql_database_instance.postgres.name
}

output "load_balancer_forwarding_rule" {
  description = "Global forwarding rule for LB"
  value       = google_compute_global_forwarding_rule.http_rule.self_link
}
