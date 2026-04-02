
# ---------------------------------------------------------------------------------
# 1. PROJECT CREATION
# ---------------------------------------------------------------------------------
resource "random_id" "project_suffix" {
  byte_length = 2
}
resource "google_project" "dev_project" {
  name            = "res-dev"
  project_id = "res-dev-${random_id.project_suffix.hex}"
  
  folder_id       = replace(trimspace(var.dev_folder_id), "folders/", "")
  billing_account = trimspace(var.billing_account)
  
  deletion_policy = "PREVENT"
}



resource "google_billing_project_info" "dev_billing" {
  project         = google_project.dev_project.project_id
  billing_account = trimspace(var.billing_account)
}

resource "time_sleep" "wait_for_billing_sync" {
  depends_on      = [google_billing_project_info.dev_billing]
  create_duration = "180s"
}


# Grant Developers access to the project
resource "google_project_iam_member" "developer_access" {
  for_each = toset(var.developer_emails)
  project  = google_project.dev_project.project_id
  role     = "roles/editor" # Or a more granular custom role
  member   = "user:${each.value}"
}



resource "time_sleep" "wait_for_apis" {
  create_duration = "60s"

  depends_on = [google_project_service.enabled_apis]
}


# ---------------------------------------------------------------------------------
# 5. SERVERLESS VPC ACCESS (The Bridge)
# ---------------------------------------------------------------------------------
resource "google_vpc_access_connector" "connector" {
  name          = "res-dev-vpc-conn-v3"
  project       = google_project.dev_project.project_id
  region        = "us-central1"
  
  subnet {
    name = google_compute_subnetwork.subnet.name
  }

  machine_type = "e2-micro"
  min_instances = 2
  max_instances = 3

  depends_on = [
    google_compute_subnetwork.subnet,
    time_sleep.wait_for_apis
  ]
}





resource "google_bigquery_dataset" "audit_logs_dataset" {
  dataset_id = "audit_logs"
  project    = var.project_id
  location   = "US"

  # This forces BigQuery to wait until the project services are active
  depends_on = [time_sleep.wait_for_apis, google_project_service.enabled_apis]
}