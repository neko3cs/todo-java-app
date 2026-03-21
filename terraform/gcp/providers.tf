provider "google" {
  project = var.project_id
  region  = var.region
  // Credentials are expected via GOOGLE_APPLICATION_CREDENTIALS env var
}

// Optional provider for region-specific resources
provider "google" {
  alias  = "region"
  project = var.project_id
  region  = var.region
}
