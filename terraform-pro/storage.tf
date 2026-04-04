# 1. The General Data Bucket
resource "random_id" "suffix" {
  byte_length = 2
}

resource "google_storage_bucket" "dev_data_bucket" {
  name                        = "res-dev-data-${random_id.suffix.hex}"
  project                     = google_project.dev_project.project_id
  location                    = "US"
  storage_class               = "STANDARD"
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"

  versioning {
    enabled = true
  }

  lifecycle_rule {
    condition {
      age = 90
    }
    action {
      type          = "SetStorageClass"
      storage_class = "NEARLINE"
    }
  }

  # THE FIX: Wait for the 60s buffer instead of just the API resource
  depends_on = [time_sleep.wait_for_apis]
}

# 2. FHIR DATA BUCKET
resource "google_storage_bucket" "fhir_storage" {
  name                        = "${google_project.dev_project.project_id}-fhir-storage"
  project                     = google_project.dev_project.project_id
  location                    = "US"
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"

  # THE FIX: Wait for the 60s buffer
  depends_on = [time_sleep.wait_for_apis]
}

# 3. Grant the AI Agent read access
resource "google_storage_bucket_iam_member" "agent_read_access" {
  bucket = google_storage_bucket.dev_data_bucket.name
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:${google_service_account.ai_agent.email}"
}

resource "google_storage_bucket_iam_member" "agent_fhir_read" {
  bucket = google_storage_bucket.fhir_storage.name
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:${google_service_account.ai_agent.email}"
}