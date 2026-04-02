# 1. The Bucket
# This generates the unique hex suffix
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

  # This block MUST be inside the google_storage_bucket resource
  lifecycle_rule {
    condition {
      age = 90
    }
    action {
      type          = "SetStorageClass"
      storage_class = "NEARLINE"
    }
  }
}

# 2. IAM - Object Admin for Developers


# 3. IAM - Object Viewer for the AI Agent
resource "google_storage_bucket_iam_member" "agent_read_access" {
  bucket = google_storage_bucket.dev_data_bucket.name
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:${google_service_account.ai_agent.email}"
}


# ---------------------------------------------------------------------------------
# 2. FHIR DATA BUCKET (Required by your outputs.tf)
# ---------------------------------------------------------------------------------
resource "google_storage_bucket" "fhir_storage" {
  name                        = "${google_project.dev_project.project_id}-fhir-storage"
  project                     = google_project.dev_project.project_id
  location                    = "US"
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"
}
# Grant the AI Agent read access to the FHIR bucket
resource "google_storage_bucket_iam_member" "agent_fhir_read" {
  bucket = google_storage_bucket.fhir_storage.name
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:${google_service_account.ai_agent.email}"
}