
# ---------------------------------------------------------------------------------
# 1. PROJECT IDENTIFICATION
# ---------------------------------------------------------------------------------
output "project_id" {
  description = "The generated Google Cloud Project ID. Set this as PROJECT_ID in GitHub Actions."
  value       = google_project.dev_project.project_id
}

output "project_number" {
  description = "The numeric Project Number."
  value       = google_project.dev_project.number
}

# ---------------------------------------------------------------------------------
# 2. RUNTIME IDENTITY (For Developer Repo)
# ---------------------------------------------------------------------------------
output "agent_runtime_service_account_email" {
  description = "The email of the Service Account for running Agents. Use this for Workload Identity."
  value       = google_service_account.agent_runtime_sa.email
}

# ---------------------------------------------------------------------------------
# 3. NETWORKING (For Cloud Run/Vertex AI Config)
# ---------------------------------------------------------------------------------
output "vpc_connector_id" {
  description = "The ID of the VPC Access Connector for Serverless egress."
  value       = google_vpc_access_connector.connector.id
}

output "subnet_id" {
  description = "The ID of the development subnet."
  value       = google_compute_subnetwork.subnet.id
}

# ---------------------------------------------------------------------------------
# 4. DEVELOPER SETUP COMMANDS (Convenience)
# ---------------------------------------------------------------------------------
output "developer_setup_guide" {
  description = "Commands for developers to run locally to sync with this infrastructure."
  value       = <<EOF

  1. Set local project:
     gcloud config set project ${google_project.dev_project.project_id}

  2. Configure Docker for Artifact Registry:
     gcloud auth configure-docker us-central1-docker.pkg.dev

  3. VPC Connector for Cloud Run (Terraform reference):
     ${google_vpc_access_connector.connector.id}

  EOF
}


# 2. Direct Link to the GCP Console
output "project_console_url" {
  description = "Direct link to the Google Cloud Console dashboard"
  value       = "https://console.cloud.google.com/welcome?project=${google_project.dev_project.project_id}"
}

# 3. The AI Agent Service Account Email
# Your developers will need this for their LangGraph/Vertex AI deployments
output "ai_agent_service_account" {
  description = "The Service Account email for AI Agent execution"
  value       = google_service_account.ai_agent.email
}

# 4. The Encrypted FHIR Bucket Name
output "fhir_data_bucket" {
  description = "The CMEK-encrypted GCS bucket for EHR data"
  value       = google_storage_bucket.fhir_storage.name
}

# 5. Developer "Quick Start" Command
# This generates a command they can copy/paste into their terminal
output "developer_setup_command" {
  description = "Run this command to set your local gcloud context"
  value       = "gcloud config set project ${google_project.dev_project.project_id}"
}

# 6. BigQuery Audit Dataset (For Compliance)
output "audit_logs_dataset_id" {
  description = "The BigQuery dataset ID where data access logs are stored"
  value       = google_bigquery_dataset.audit_logs_dataset.dataset_id
}