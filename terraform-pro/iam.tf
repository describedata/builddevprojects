
# ---------------------------------------------------------------------------------
# 1. THE AGENT RUNTIME IDENTITY (The "Brain")
# ---------------------------------------------------------------------------------
# This service account is what actually "runs" the LangGraph/Vertex AI agents.
# It is the identity used by Cloud Run and Vertex AI Reasoning Engine.

resource "google_service_account" "agent_runtime_sa" {
  project      = google_project.dev_project.project_id
  account_id   = "agent-runtime-sa"
  display_name = "Identity for Vertex AI and Cloud Run Agents"
}

# ---------------------------------------------------------------------------------
# 2. DEVELOPER GROUP PERMISSIONS (The "Builder" Access)
# ---------------------------------------------------------------------------------
# These roles are granted to the Developer Group (var.developer_group_email).
# It allows them to use all services without having Project "Owner" or "Admin" rights.

resource "google_project_iam_member" "developer_roles" {
  for_each = toset([
    "roles/viewer",                     # Global visibility of the console
    "roles/aiplatform.user",            # Run/Test Vertex AI Agents and Notebooks
    "roles/run.developer",              # Deploy/Manage Cloud Run services
    "roles/artifactregistry.writer",    # Push/Pull Docker images
    "roles/logging.viewer",             # View logs for debugging agents
    "roles/monitoring.viewer",          # View performance dashboards
    "roles/cloudtrace.user",            # Trace request flow through agents
    "roles/secretmanager.secretAccessor", # Read API keys (Neo4j, LLM keys)
    "roles/vpcaccess.user"              # Permission to use the VPC Connector
  ])

  project = google_project.dev_project.project_id
  role    = each.key
  member  = "group:${var.developer_group_email}"
}

# ---------------------------------------------------------------------------------
# 3. SERVICE ACCOUNT IMPERSONATION (The Security Bridge)
# ---------------------------------------------------------------------------------
# This allows developers to "Act As" the agent-runtime-sa.
# They need this to deploy a Cloud Run service using that specific identity.

resource "google_service_account_iam_member" "developer_impersonation" {
  service_account_id = google_service_account.agent_runtime_sa.name
  role               = "roles/iam.serviceAccountUser"
  member             = "group:${var.developer_group_email}"
}

# ---------------------------------------------------------------------------------
# 4. NETWORK & SUBNET USAGE (VPC Security)
# ---------------------------------------------------------------------------------
# Even with Run Developer rights, GCP requires explicit permission to attach 
# a service to a specific private subnet.

resource "google_compute_subnetwork_iam_member" "subnet_usage" {
  project    = google_project.dev_project.project_id
  region     = var.region
  subnetwork = google_compute_subnetwork.subnet.name
  role       = "roles/compute.networkUser"
  member     = "group:${var.developer_group_email}"
}

# ---------------------------------------------------------------------------------
# 5. STORAGE DATA ACCESS (Bucket-Level Security)
# ---------------------------------------------------------------------------------
# Developers manage the data (CSVs, JSONs, FHIR samples).
# The Agent only needs to read that data.

# Developers: Full control over files (Object Admin)
resource "google_storage_bucket_iam_member" "dev_data_access" {
  bucket = google_storage_bucket.dev_data_bucket.name
  role   = "roles/storage.objectAdmin"
  member = "group:${var.developer_group_email}"
}

# AI Agent: Read-only access to files (Object Viewer)
resource "google_storage_bucket_iam_member" "agent_read_access" {
  bucket = google_storage_bucket.dev_data_bucket.name
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:${google_service_account.agent_runtime_sa.email}"
}

# ---------------------------------------------------------------------------------
# 6. WORKLOAD IDENTITY FEDERATION (For GitHub Actions)
# ---------------------------------------------------------------------------------
# This allows the Developer Repo (GitHub Actions) to deploy to this project
# by impersonating the runtime SA without needing a JSON key.

resource "google_service_account_iam_member" "github_actions_impersonation" {
  service_account_id = google_service_account.agent_runtime_sa.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/projects/${google_project.dev_project.number}/locations/global/workloadIdentityPools/github-actions-pool/attribute.repository/YOUR_ORG/agent-deployments"
}
