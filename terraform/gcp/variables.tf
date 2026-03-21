variable "project_id" {
  description = "GCP project id"
  type        = string
}

variable "region" {
  description = "Primary region for resources (Cloud Run, SQL, etc.)"
  type        = string
  default     = "us-central1"
}

variable "network_name" {
  description = "VPC name to create or use"
  type        = string
  default     = "todo-vpc"
}

variable "subnet_cidr" {
  description = "CIDR range for subnet"
  type        = string
  default     = "10.10.0.0/24"
}

variable "connector_name" {
  description = "Serverless VPC Access connector name"
  type        = string
  default     = "serverless-connector"
}

variable "cloud_run_region" {
  description = "Region for Cloud Run"
  type        = string
  default     = "us-central1"
}

variable "sql_instance_name" {
  description = "Cloud SQL instance name"
  type        = string
  default     = "todo-sql"
}

variable "sql_tier" {
  description = "Cloud SQL machine type"
  type        = string
  default     = "db-f1-micro"
}

variable "service_account_email" {
  description = "Optional service account email for app / Terraform operations"
  type        = string
  default     = ""
}

variable "enable_post_deploy_ingress" {
  description = "If true, run a post-deploy gcloud command to enforce Cloud Run ingress (workaround for provider limitations)"
  type        = bool
  default     = false
}

variable "remote_state_bucket" {
  description = "Optional GCS bucket name for Terraform remote state (create and grant permissions before use)"
  type        = string
  default     = ""
}

variable "remote_state_prefix" {
  description = "Optional prefix/path inside the GCS bucket for Terraform state files"
  type        = string
  default     = "terraform/state"
}

variable "domain_name" {
  description = "Optional domain name for LB SSL; leave empty if not used"
  type        = string
  default     = ""
}
