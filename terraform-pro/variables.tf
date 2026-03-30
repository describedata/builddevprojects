

# ---------------------------------------------------------------------------------
# 1. IDENTIFICATION & HIERARCHY
# ---------------------------------------------------------------------------------

variable "org_id" {
  description = "The numeric Organization ID where the project will be created."
  type        = string
}

variable "project_name" {
  description = "The display name of the project"
  type        = string
}

variable "project_id" {
  description = "The unique ID (e.g., ai-dev)"
  type        = string
}

variable "folder_id" {
  description = "The Folder ID where this project will be nested"
  type        = string
}
variable "dev_folder_id" {
  description = "The Folder ID (numeric or 'folders/123') where the dev project lives."
  type        = string
}

variable "billing_account" {
  description = "The 18-character alphanumeric Billing Account ID (XXXXXX-XXXXXX-XXXXXX)."
  type        = string
}

variable "customer_id" {
  description = "The Customer ID for Cloud Identity (starts with C)"
  type        = string
  default     = "C0320vp24" # Replace with your actual ID
}

# ---------------------------------------------------------------------------------
# 2. REGIONAL SETTINGS
# ---------------------------------------------------------------------------------

variable "region" {
  description = "The primary GCP region for networking and resources."
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "The primary GCP zone for compute resources."
  type        = string
  default     = "us-central1-a"
}

# ---------------------------------------------------------------------------------
# 3. ACCESS CONTROL
# ---------------------------------------------------------------------------------



variable "developer_group_email" {
  default = "group:developers@describedata.ai" # Must include the 'group:' prefix
  description = "The Google Group or individual email for the developer team (e.g., group:devs@company.com)."
  type        = string
}

variable "developer_emails" {
  description = "A list of Google Workspace emails/groups for developer access"
  type        = list(string)
  # Example: ["user1@domain.com", "user2@domain.com"]
}

#variable "developer_emails" {
#  description = "A list of Google Workspace emails/groups for developer access"

#  type        = list(string)
  # Example: ["user1@domain.com", "user2@domain.com"]
#}

# ---------------------------------------------------------------------------------
# 4. NETWORKING
# ---------------------------------------------------------------------------------

variable "vpc_name" {
  description = "The name of the VPC network."
  type        = string
  default     = "ai-dev-vpc"
}

variable "subnet_cidr" {
  description = "The IP range for the primary development subnet."
  type        = string
  default     = "10.0.1.0/24"
}

# ---------------------------------------------------------------------------------
# 3. IDENTITY & STORAGE
# ---------------------------------------------------------------------------------

output "agent_runtime_service_account" {
  description = "The email of the SA that developers must use for their agents."
  value       = google_service_account.agent_runtime_sa.email
}

output "data_bucket_url" {
  description = "The GCS bucket URL for uploading EHR/FHIR data."
  value       = "gs://${google_storage_bucket.dev_data_bucket.name}"
}

# ---------------------------------------------------------------------------------
# 4. REPOSITORY INFO
# ---------------------------------------------------------------------------------

output "artifact_registry_repo" {
  description = "The full path to the Docker repository for agent images."
  value       = "${var.region}-docker.pkg.dev/${google_project.dev_project.project_id}/agent-repo"
}