# ==========================================
# PROJECT IDENTIFICATION
# ==========================================
# Note: projects.tf will append a random suffix to this (e.g., ai-dev-a1b2)
project_name = "ai-dev"

# ==========================================
# HIERARCHY & BILLING
# ==========================================
billing_account = "012345-67890A-BCDEFF"

# The folder where the project will be created
dev_folder_id   = "376680453575"

# Your Google Workspace / Cloud Identity Customer ID (Starts with C)
# Found in Admin Console > Account > Account Settings
customer_id     = "C01234567" 

# ==========================================
# ACCESS CONTROL (TEAM)
# ==========================================
# This is the central group that will own all permissions.
# MUST include the 'group:' prefix for your IAM code to work.
developer_group_email = "group:developers@describedata.ai"

# ==========================================
# REGIONAL SETTINGS
# ==========================================
region          = "us-central1"
zone            = "us-central1-a"