
# 1. Create a Bucket for Developer Data (e.g., FHIR samples, CSVs)
resource "google_storage_bucket" "dev_data_bucket" {
  name          = "${google_project.dev_project.project_id}-data"
  project       = google_project.dev_project.project_id
  location      = "US" # Multi-region for high availability
  storage_class = "STANDARD"

  # MANDATORY for modern GCP: Manage everything via IAM, not ACLs
  uniform_bucket_level_access = true

  # Security: Prevent the bucket from being public
  public_access_prevention = "enforced"

  # Optional: Keep 3 versions of every file to protect against accidental deletes
  versioning {
    enabled = true
  }

  # Cost Control: Move objects to cheaper storage after 90 days
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

# 2. IAM: Grant Developers the "Object Admin" role
# This lets them upload, read, and delete files, but NOT delete the bucket itself.
resource "google_storage_bucket_iam_member" "dev_bucket_access" {
  bucket = google_storage_bucket.dev_data_bucket.name
  role   = "roles/storage.objectAdmin"
  member = "group:developers@yourcompany.com"
}

# 3. IAM: Grant your "Agent" Service Account access
# Your AI Agent only needs to READ the data to process it.
resource "google_storage_bucket_iam_member" "agent_read_access" {
  bucket = google_storage_bucket.dev_data_bucket.name
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:${google_service_account.agent_runtime_sa.email}"
}


  # Lifecycle: Archive data older than 1 year to Coldline to save costs
  lifecycle_rule {
    condition {
      age = 365
    }
    action {
      type          = "SetStorageClass"
      storage_class = "COLDLINE"
    }
  }

  depends_on = [google_kms_crypto_key_iam_member.gcs_kms_binding]
}

