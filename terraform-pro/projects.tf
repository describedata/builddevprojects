
# ---------------------------------------------------------------------------------
# 1. PROJECT CREATION
# ---------------------------------------------------------------------------------
resource "random_id" "suffix" {
  byte_length = 2
}

resource "google_project" "dev_project" {
  name            = "ai-dev"
  project_id      = var.project_id # Using the ID from your GitHub Secret
  
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
  create_duration = "120s"
}




# ---------------------------------------------------------------------------------
# 5. SERVERLESS VPC ACCESS (The Bridge)
# ---------------------------------------------------------------------------------
resource "google_vpc_access_connector" "connector" {
  name          = "ai-dev-vpc-conn"
  project       = google_project.dev_project.project_id
  region        = "us-central1"
  
  subnet {
    name = google_compute_subnetwork.subnet.name
  }

  machine_type = "e2-micro"
  min_instances = 2
  max_instances = 3
}


# ---------------------------------------------------------------------------------
# 4. BIGQUERY (AUDIT LOGS)
# ---------------------------------------------------------------------------------
resource "google_bigquery_dataset" "audit_logs_dataset" {
  dataset_id = "audit_logs"
  project    = google_project.dev_project.project_id
  location   = "US"

  depends_on = [time_sleep.wait_for_billing_sync]
}