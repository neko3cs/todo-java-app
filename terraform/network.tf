# VPC + Subnet
resource "google_compute_network" "main" {
  name                    = "dev-infra-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "main" {
  name          = "dev-infra-subnet"
  ip_cidr_range = "10.10.0.0/24"
  region        = var.region
  network       = google_compute_network.main.id
}

# Reserve an internal IP range for private services (private services access)
resource "google_compute_global_address" "private_range" {
  name          = "private-services-range"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
}

# Establish Private Services Access for Cloud SQL (service networking)
resource "google_service_networking_connection" "private_vpc" {
  network                 = google_compute_network.main.self_link
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_range.name]

  depends_on = [google_project_service.enabled]
}
