# ---------------------------------------------------------------------------------
# 1. PROJECT SYNC (The "Adoption" Block)
# ---------------------------------------------------------------------------------
# This tells the GitHub Action to adopt the existing project into the state file.
import {
  to = google_project.dev_project
  id = "res-dev-d1ba"
}

resource "google_project" "dev_project" {
  name       = "res-dev"
  # Hardcode this ID for now since it already exists in GCP
  project_id = "res-dev-d1ba" 
  
  folder_id       = replace(trimspace(var.dev_folder_id), "folders/", "")
  billing_account = trimspace(var.billing_account)
  
  # Prevents accidental deletion during future Platform Repo runs
  deletion_policy = "PREVENT"
}

# ---------------------------------------------------------------------------------
# 2. BILLING & PROPAGATION
# ---------------------------------------------------------------------------------
resource "google_billing_project_info" "dev_billing" {
  project         = google_project.dev_project.project_id
  billing_account = trimspace(var.billing_account)
}

resource "time_sleep" "wait_for_billing_sync" {
  depends_on      = [google_billing_project_info.dev_billing]
  create_duration = "180s" # Keep this at 3 mins to ensure APIs don't 403
}

# ---------------------------------------------------------------------------------
# 3. IAM & API ENABLING
# ---------------------------------------------------------------------------------
# Grant Developers access to the project
resource "google_project_iam_member" "developer_access" {
  for_each = toset(var.developer_emails)
  project  = google_project.dev_project.project_id
  role     = "roles/editor"
  member   = "user:${each.value}"
}

# Note: Ensure google_project_service.enabled_apis is defined elsewhere
# using google_project.dev_project.project_id
resource "time_sleep" "wait_for_apis" {
  create_duration = "60s"
  depends_on      = [google_project_service.enabled_apis]
}

# ---------------------------------------------------------------------------------
# 4. SERVERLESS VPC ACCESS & BIGQUERY
# ---------------------------------------------------------------------------------
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
    google_project_iam_member.developer_access # Ensure roles are set first
  ]
}

resource "google_bigquery_dataset" "audit_logs_dataset" {
  dataset_id = "audit_logs"
  # FIX: Change var.project_id to the direct resource reference
  project    = google_project.dev_project.project_id
  location   = "US"

  depends_on = [
    time_sleep.wait_for_apis, 
    google_project_service.enabled_apis
  ]
}