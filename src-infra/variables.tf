variable "project_id" {
  type        = string
  description = "GCP project id"
}

variable "region" {
  type        = string
  description = "GCP region for regional resources"
  default     = "us-central1"
}

variable "cloud_run_image" {
  type        = string
  description = "Container image for Cloud Run service (e.g. gcr.io/project/image:tag)"
}

variable "db_tier" {
  type        = string
  description = "Cloud SQL machine tier"
  default     = "db-f1-micro"
}

variable "db_instance_name" {
  type        = string
  description = "Cloud SQL instance name"
  default     = "pg-instance"
}

variable "cloud_run_service_name" {
  type        = string
  description = "Cloud Run service name"
  default     = "app-service"
}

variable "lb_invoker_sa" {
  type        = string
  description = "Service account member (e.g. \"serviceAccount:...\") to grant run.invoker to for load balancer invocation. Leave empty to skip creating the IAM binding."
  default     = ""
}
