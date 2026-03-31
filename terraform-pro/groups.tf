# ---------------------------------------------------------------------------------
# 1. CREATE THE IDENTITY GROUP
# ---------------------------------------------------------------------------------

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



