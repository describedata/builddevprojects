
# ---------------------------------------------------------------------------------
# 1. PRIMARY API ENABLER (WITH BILLING WAIT)
# ---------------------------------------------------------------------------------
# This resource loops through all required APIs and enables them.
# It MUST wait for the 'wait_for_billing_sync' timer defined in projects.tf.

resource "google_project_service" "enabled_apis" {
  for_each = toset([
    "compute.googleapis.com",             # Required for VPC and NAT
    "run.googleapis.com",                 # Required for Cloud Run Agents
    "artifactregistry.googleapis.com",    # Required for Docker Images
    "aiplatform.googleapis.com",          # Required for Vertex AI / Agents
    "iam.googleapis.com",                 # Required for Service Accounts/Roles
    "cloudresourcemanager.googleapis.com",# Required for Project/IAM management
    "vpcaccess.googleapis.com",           # Required for Serverless VPC Access
    "logging.googleapis.com",             # Required for Log Explorer
    "monitoring.googleapis.com",          # Required for Dashboards
    "secretmanager.googleapis.com",       # Required for API Keys/Secrets
   "cloudbuild.googleapis.com",
    "serviceusage.googleapis.com",
    "
  ])

  project = google_project.dev_project.project_id
  service = each.key

  # CRITICAL FIX: 
  # This prevents the "Billing account not found" error by forcing a 60s pause.
  depends_on = [time_sleep.wait_for_billing_sync]

    # Crucial: Ensure the project exists before enabling APIs
  #depends_on = [google_project.dev_project]

  # Optional: Prevents APIs from being disabled if you remove them from the list
  # and run terraform apply again (useful for stability).
  disable_on_destroy = false
}

# ---------------------------------------------------------------------------------
# 2. ADDITIONAL API CONFIGURATION (OPTIONAL)
# ---------------------------------------------------------------------------------
# If you plan on using specific specialized services like Firestore or BigQuery 
# for EHR data, you can add them to the list above.

# Note: Some APIs (like aiplatform) can take up to 2 minutes to fully propagate.
# If your developer repo fails on the first run, simply retry the action.
