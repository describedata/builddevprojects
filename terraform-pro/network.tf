

# 1. Create the VPC
resource "google_compute_network" "vpc" {
  name                    = "res-dev-vpc"
  project                 = google_project.dev_project.project_id
  auto_create_subnetworks = false

  # MUST wait for billing AND the API to be ready
  depends_on = [
    time_sleep.wait_for_billing_sync,
    google_project_service.enabled_apis
  ]
}

# 2. Create a Private Subnet

resource "google_compute_subnetwork" "subnet" {
  name          = "res-dev-subnet-v3"
  # Shift the IP range slightly to bypass the lock
  # Old: 10.8.0.0/28 -> New: 10.8.1.0/28
  ip_cidr_range = "10.8.1.0/28"
  region        = "us-central1"
  project       = google_project.dev_project.project_id
  network       = google_compute_network.vpc.id
  # Allows resources to use Google APIs without public IPs
  private_ip_google_access = true 

  # This helps, but the real fix is in the connector dependency
  lifecycle {
    create_before_destroy = true 
  }
}

# 3. Create Cloud NAT (So Private Agents can reach the Internet)
resource "google_compute_router" "router" {
  name    = "res-dev-router"
  project = google_project.dev_project.project_id
  region  = "us-central1"
  network = google_compute_network.vpc.id
}

resource "google_compute_router_nat" "nat" {
  name                               = "ai-dev-nat"
  project                            = google_project.dev_project.project_id
  router                             = google_compute_router.router.name
  region                             = "us-central1"
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}
