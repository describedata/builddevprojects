# ---------------------------------------------------------------------------------
# 1. PRIMARY API ENABLER (WITH BILLING WAIT)
# ---------------------------------------------------------------------------------
# This resource loops through all required APIs and enables them.
resource "google_project_service" "enabled_apis" {
  for_each = toset([
    "compute.googleapis.com",              # Required for VPC and NAT
    "run.googleapis.com",                  # Required for Cloud Run Agents
    "artifactregistry.googleapis.com",     # Required for Docker Images
    "aiplatform.googleapis.com",           # Required for Vertex AI / Agents
    "iam.googleapis.com",                  # Required for Service Accounts/Roles
    "cloudresourcemanager.googleapis.com", # Required for Project/IAM management
    "vpcaccess.googleapis.com",            # Required for Serverless VPC Access
    "logging.googleapis.com",              # Required for Log Explorer
    "monitoring.googleapis.com",           # Required for Dashboards
    "secretmanager.googleapis.com",        # Required for API Keys/Secrets
    "cloudbuild.googleapis.com",           # Required for CI/CD
    "serviceusage.googleapis.com",         # Required for enabling other APIs
    "bigquery.googleapis.com"              # FIX: Required for audit_logs_dataset
  ])

  project = google_project.dev_project.project_id
  service = each.key

  # Prevents "Billing account not found" by waiting for the 3-minute sync
  depends_on = [time_sleep.wait_for_billing_sync]

  # Stability: Prevents APIs from being disabled if removed from list later
  disable_on_destroy = false
}

# ---------------------------------------------------------------------------------
# 2. THE MASTER PROPAGATION BUFFER
# ---------------------------------------------------------------------------------
# This is the central timer that downstream resources (BigQuery, VPC, Storage)
# must wait for to ensure GCP's backend is fully ready.
resource "time_sleep" "wait_for_apis" {
  depends_on      = [google_project_service.enabled_apis]
  create_duration = "60s"
}