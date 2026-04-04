# ---------------------------------------------------------------------------------
# 1. THE AGENT RUNTIME IDENTITY (The "Brain")
# ---------------------------------------------------------------------------------
resource "google_service_account" "ai_agent" {
  account_id   = "ai-agent-sa" 
  display_name = "AI Agent Service Account"
  project      = google_project.dev_project.project_id
}

# ---------------------------------------------------------------------------------
# 2. DEVELOPER GROUP PERMISSIONS (The "Builder" Access)
# ---------------------------------------------------------------------------------
resource "google_project_iam_member" "developer_roles" {
  # FIX: Wrapping in toset() prevents "Duplicate Object Key" errors if a role or 
  # email is accidentally listed twice in your variables.
  for_each = {
    for pair in setproduct(toset(var.developer_roles), toset(var.developer_emails)) :
    "${pair[1]}-${pair[0]}" => {
      role   = pair[0]
      member = pair[1]
    }
  }

  project = google_project.dev_project.project_id
  role    = each.value.role
  member  = "user:${each.value.member}"
}

# ---------------------------------------------------------------------------------
# 3. SERVICE ACCOUNT IMPERSONATION (The Security Bridge)
# ---------------------------------------------------------------------------------
resource "google_service_account_iam_member" "developer_impersonation" {
  service_account_id = google_service_account.ai_agent.name
  role               = "roles/iam.serviceAccountUser"
  
  # Ensure this group exists in your Workspace/Cloud Identity
  member = "group:developers@describedata.ai"
}

# ---------------------------------------------------------------------------------
# 4. NETWORK & SUBNET USAGE (VPC Security)
# ---------------------------------------------------------------------------------
resource "google_compute_subnetwork_iam_member" "subnet_usage" {
  for_each = toset(var.developer_emails)

  project    = google_project.dev_project.project_id
  region     = var.region
  subnetwork = google_compute_subnetwork.subnet.name
  role       = "roles/compute.networkUser"
  member     = "user:${each.value}"
}

# ---------------------------------------------------------------------------------
# 6. WORKLOAD IDENTITY FEDERATION (For GitHub Actions)
# ---------------------------------------------------------------------------------
resource "google_service_account_iam_member" "github_actions_impersonation" {
  service_account_id = google_service_account.ai_agent.name
  role               = "roles/iam.serviceAccountTokenCreator"
  
  # CRITICAL CHECK: Ensure project '571707457370' is your SEED/INFRA project 
  # where the Workload Identity Pool actually lives.
  member = "principalSet://iam.googleapis.com/projects/571707457370/locations/global/workloadIdentityPools/github-actions-pool/attribute.repository/describedata/builddevprojects"
}