
# ---------------------------------------------------------------------------------
# 1. PROJECT CREATION
# ---------------------------------------------------------------------------------
resource "random_id" "suffix" {
  byte_length = 2
}

resource "google_project" "dev_project" {
  name            = "ai-dev"
  project_id      = "ai-dev-${random_id.suffix.hex}"
  
  # Logic: Clean the Folder ID and Billing Account strings
  folder_id       = replace(trimspace(var.dev_folder_id), "folders/", "")
  billing_account = trimspace(var.billing_account)
  
  deletion_policy = "PREVENT"
}

# ---------------------------------------------------------------------------------
# 2. BILLING STABILIZATION (The "Speed Bump")
# ---------------------------------------------------------------------------------
# This resource explicitly links the project to billing and forces a wait.
# This prevents "Billing account not found" errors in services.tf.

resource "google_billing_project_info" "dev_billing" {
  project         = google_project.dev_project.project_id
  billing_account = trimspace(var.billing_account)
}

resource "time_sleep" "wait_for_billing_sync" {
  depends_on      = [google_billing_project_info.dev_billing]
  create_duration = "60s"
}

# ---------------------------------------------------------------------------------
# 3. CLOUD IDENTITY GROUP CREATION
# ---------------------------------------------------------------------------------
# This creates the central "developers@yourdomain.com" group.
# Note: Requires 'google-beta' provider and Group Admin permissions.

resource "google_cloud_identity_group" "dev_group" {
  provider     = google-beta
  parent       = "customers/${var.customer_id}"
  display_name = "AI Developer Team"
  description  = "Access group for the ai-dev project resources"

  group_key {
    id = var.developer_group_email
  }

  labels = {
    "cloudidentity.googleapis.com/groups.discussion_forum" = ""
  }
}

# ---------------------------------------------------------------------------------
# 4. INITIAL GROUP MEMBERSHIP
# ---------------------------------------------------------------------------------
# Automatically adds you (the Architect) to the group you just created.

resource "google_cloud_identity_group_membership" "admin_member" {
  provider = google-beta
  group    = google_cloud_identity_group.dev_group.id

  preferred_member_key {
    id = "girish@describedata.ai" # Update to your primary email
  }

  roles {
    name = "MEMBER"
  }
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
# 6. SHARED NETWORK (VPC)
# ---------------------------------------------------------------------------------
resource "google_compute_network" "vpc" {
  name                    = "ai-dev-vpc"
  project                 = google_project.dev_project.project_id
  auto_create_subnetworks = false
  depends_on              = [time_sleep.wait_for_billing_sync]
}

resource "google_compute_subnetwork" "subnet" {
  name                     = "ai-dev-subnet"
  project                  = google_project.dev_project.project_id
  ip_cidr_range            = "10.0.1.0/24"
  region                   = "us-central1"
  network                  = google_compute_network.vpc.id
  private_ip_google_access = true
}


# ---------------------------------------------------------------------------------
# 3. SERVICE ACCOUNTS & DEVELOPER IAM
# ---------------------------------------------------------------------------------

# The "Agent Identity" that developers will use for Vertex AI and Cloud Run
resource "google_service_account" "agent_runtime_sa" {
  project      = google_project.dev_project.project_id
  account_id   = "agent-runtime-sa"
  display_name = "Restricted Runtime Identity for AI Agents"
}

# Grant Developers the ability to "Act As" this Service Account (Impersonation)
# This allows them to deploy without having Project Admin/Owner rights.
resource "google_service_account_iam_member" "developer_impersonation" {
  service_account_id = google_service_account.agent_runtime_sa.name
  role               = "roles/iam.serviceAccountUser"
  member             = "group:developers@describedata.ai" # Update to your group/email
}