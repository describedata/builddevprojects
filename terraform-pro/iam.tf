
# ---------------------------------------------------------------------------------
# 1. THE AGENT RUNTIME IDENTITY (The "Brain")
# ---------------------------------------------------------------------------------
# This service account is what actually "runs" the LangGraph/Vertex AI agents.
# It is the identity used by Cloud Run and Vertex AI Reasoning Engine.

resource "google_service_account" "ai_agent" {
  account_id   = "ai-agent-sa"  # <--- Change "_" to "-" here
  display_name = "AI Agent Service Account"
  project      = google_project.dev_project.project_id
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
  member = "group:developers@describedata.ai"

  # ADD THIS LINE:
  depends_on = [google_cloud_identity_group.dev_group]
}

# ---------------------------------------------------------------------------------
# 3. SERVICE ACCOUNT IMPERSONATION (The Security Bridge)
# ---------------------------------------------------------------------------------
# This allows developers to "Act As" the agent-runtime-sa.
# They need this to deploy a Cloud Run service using that specific identity.

resource "google_service_account_iam_member" "developer_impersonation" {
  service_account_id = google_service_account.ai_agent.name
  role               = "roles/iam.serviceAccountUser"
  member = "group:developers@describedata.ai"
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


# AI Agent: Read-only access to files (Object Viewer)


# ---------------------------------------------------------------------------------
# 6. WORKLOAD IDENTITY FEDERATION (For GitHub Actions)
# ---------------------------------------------------------------------------------
# This allows the Developer Repo (GitHub Actions) to deploy to this project
# by impersonating the runtime SA without needing a JSON key.

resource "google_service_account_iam_member" "github_actions_impersonation" {
  service_account_id = google_service_account.ai_agent.name
  role               = "roles/iam.workloadIdentityUser"
  member = "principalSet://iam.googleapis.com/projects/audit-terraform-seed/locations/global/workloadIdentityPools/github-actions-pool/attribute.repository/describedata/builddevprojects"
}
