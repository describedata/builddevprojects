# ---------------------------------------------------------------------------------
# 1. PROJECT SYNC (The "Adoption" Block)
# ---------------------------------------------------------------------------------
import {
  to = google_project.dev_project
  id = "res-dev-d1ba"
}

resource "google_project" "dev_project" {
  name            = "res-dev"
  project_id      = "res-dev-d1ba" 
  folder_id       = replace(trimspace(var.dev_folder_id), "folders/", "")
  billing_account = trimspace(var.billing_account)
  deletion_policy = "PREVENT"
}

# ---------------------------------------------------------------------------------
# 2. API ENABLING & PROPAGATION BUFFER
# ---------------------------------------------------------------------------------
resource "google_project_service" "enabled_apis" {
  for_each = toset([
    "compute.googleapis.com",
    "run.googleapis.com",
    "aiplatform.googleapis.com",
    "bigquery.googleapis.com",
    "logging.googleapis.com",
    "secretmanager.googleapis.com",
    "vpcaccess.googleapis.com"
  ])

  project            = google_project.dev_project.project_id
  service            = each.key
  disable_on_destroy = false
}

# THE MASTER BUFFER: Use this for BigQuery, VPC, and Storage
resource "time_sleep" "wait_for_apis" {
  depends_on      = [google_project_service.enabled_apis]
  create_duration = "60s"
}

# ---------------------------------------------------------------------------------
# 3. BILLING & IAM
# ---------------------------------------------------------------------------------
resource "google_billing_project_info" "dev_billing" {
  project         = google_project.dev_project.project_id
  billing_account = trimspace(var.billing_account)
}

resource "google_project_iam_member" "developer_access" {
  for_each = toset(var.developer_emails)
  project  = google_project.dev_project.project_id
  role     = "roles/editor"
  member   = "user:${each.value}"
}

# ---------------------------------------------------------------------------------
# 4. DOWNSTREAM RESOURCES (Dependent on Buffer)
# ---------------------------------------------------------------------------------
resource "google_bigquery_dataset" "audit_logs_dataset" {
  dataset_id = "audit_logs"
  project    = google_project.dev_project.project_id
  location   = "US"
  depends_on = [time_sleep.wait_for_apis]
}

resource "google_vpc_access_connector" "connector" {
  name    = "res-dev-vpc-conn-v3"
  project = google_project.dev_project.project_id
  region  = "us-central1"
  
  subnet {
    name = google_compute_subnetwork.subnet.name
  }

  machine_type = "e2-micro"
  min_instances = 2
  max_instances = 3

  depends_on = [
    google_compute_subnetwork.subnet,
    time_sleep.wait_for_apis,
    google_project_iam_member.developer_access
  ]
}