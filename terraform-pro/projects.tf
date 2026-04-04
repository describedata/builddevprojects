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
# 2. BILLING & PROPAGATION
# ---------------------------------------------------------------------------------
resource "google_billing_project_info" "dev_billing" {
  project         = google_project.dev_project.project_id
  billing_account = trimspace(var.billing_account)
}

resource "time_sleep" "wait_for_billing_sync" {
  depends_on      = [google_billing_project_info.dev_billing]
  create_duration = "180s" # 3-minute wait for billing to propagate
}

# ---------------------------------------------------------------------------------
# 3. IAM & ACCESS
# ---------------------------------------------------------------------------------
resource "google_project_iam_member" "developer_access" {
  for_each = toset(var.developer_emails)
  project  = google_project.dev_project.project_id
  role     = "roles/editor"
  member   = "user:${each.value}"
}

# ---------------------------------------------------------------------------------
# 4. DOWNSTREAM RESOURCES (Dependent on Buffer in services.tf)
# ---------------------------------------------------------------------------------
resource "google_bigquery_dataset" "audit_logs_dataset" {
  dataset_id = "audit_logs"
  project    = google_project.dev_project.project_id
  location   = "US"

  # CRITICAL: This now references the buffer defined in services.tf
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
    time_sleep.wait_for_apis, # Reference from services.tf
    google_project_iam_member.developer_access
  ]
}