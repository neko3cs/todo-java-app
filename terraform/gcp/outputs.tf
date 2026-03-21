output "forwarding_rule_ip" {
  description = "IP address of the global forwarding rule"
  value       = google_compute_global_forwarding_rule.http_forward.ip_address
}

output "cloud_sql_instance" {
  description = "Cloud SQL instance connection name"
  value       = google_sql_database_instance.postgres.connection_name
}

output "cloud_run_service" {
  description = "Cloud Run service name"
  value       = google_cloud_run_service.app.status[0].url
}

output "security_policy_name" {
  description = "Cloud Armor security policy name"
  value       = google_compute_security_policy.waf_policy.name
}
