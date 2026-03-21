# VPC and Serverless VPC Access connector
resource "google_compute_network" "default" {
  name                    = var.network_name
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "private" {
  name          = "${var.network_name}-subnet"
  ip_cidr_range = var.subnet_cidr
  network       = google_compute_network.default.id
  region        = var.region
}

resource "google_vpc_access_connector" "serverless" {
  name   = var.connector_name
  region = var.cloud_run_region
  network = google_compute_network.default.name
  ip_cidr_range = "10.8.0.0/28"
}
