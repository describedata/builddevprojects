# ---------------------------------------------------------------------------------
# 1. CREATE THE IDENTITY GROUP
# ---------------------------------------------------------------------------------
resource "google_cloud_identity_group" "dev_group" {
  # Use google-beta for Identity Platform resources
  provider     = google-beta
  
  # The parent must be in the 'customers/CXXXXX' format
  parent       = "customers/${var.customer_id}"
  
  display_name = "Cloud Developer Team"
  description  = "Group for developers to access the ai-dev project resources"

  # The primary email identifier for the group
  group_key {
    id = "developers@describedata.ai" 
  }

  # This label is required by Google to identify it as a security/discussion group
  labels = {
    "cloudidentity.googleapis.com/groups.discussion_forum" = ""
  }
}

# ---------------------------------------------------------------------------------
# 2. ADD INITIAL MEMBERS (Optional)
# ---------------------------------------------------------------------------------
# You can add yourself or other lead developers here. 
# Future members can be added via the UI or by adding more blocks here.

resource "google_cloud_identity_group_membership" "lead_dev" {
  provider = google-beta
  group    = google_cloud_identity_group.dev_group.id

  preferred_member_key {
    id = "girishv@describedataai"
  }

  roles {
    name = "MEMBER"
  }
}



