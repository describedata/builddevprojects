
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
  # This creates a unique key for every [User + Role] combination
  for_each = {
    for pair in setproduct(var.developer_roles, var.developer_emails) :
    "${pair[1]}-${pair[0]}" => {
      role   = pair[0]
      member = pair[1]
    }
  }

  project = google_project.dev_project.project_id
  role    = each.value.role
  
  # FIX: Ensure 'user:' is prefixed to the email address (member)
  member  = "user:${each.value.member}"
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
  # This loops through your list: ['girishv@...', 'rekhar@...', 'lead_engineer@...']
  for_each = toset(var.developer_emails)

  project    = google_project.dev_project.project_id
  region     = var.region
  subnetwork = google_compute_subnetwork.subnet.name
  role       = "roles/compute.networkUser"
  
  # CHANGE: We now use 'user:' and reference the current email in the loop
  member     = "user:${each.value}"
}


# ---------------------------------------------------------------------------------
# 6. WORKLOAD IDENTITY FEDERATION (For GitHub Actions)
# ---------------------------------------------------------------------------------
# This allows the Developer Repo (GitHub Actions) to deploy to this project
# by impersonating the runtime SA without needing a JSON key.
resource "google_service_account_iam_member" "github_actions_impersonation" {
  service_account_id = google_service_account.ai_agent.name
  role               = "roles/iam.serviceAccountTokenCreator"
  
  # Remove the double slash and ensure the prefix is correct
  member = "principalSet://iam.googleapis.com/projects/571707457370/locations/global/workloadIdentityPools/github-actions-pool/attribute.repository/describedata/builddevprojects"
}