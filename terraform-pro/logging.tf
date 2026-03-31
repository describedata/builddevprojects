# 1. Enable Logging and Monitoring APIs
resource "google_project_service" "logging_apis" {
  for_each = toset([
    "logging.googleapis.com",
    "monitoring.googleapis.com",
    "cloudtrace.googleapis.com"
  ])

  project = google_project.dev_project.project_id
  service = each.key

  # Wait for billing sync before enabling
  depends_on = [time_sleep.wait_for_billing_sync]
}

# 2. Create a Log Bucket for Long-term Storage
# This is where all Agent and Cloud Run logs will live.
resource "google_logging_project_bucket_config" "developer_logs" {
  project        = google_project.dev_project.project_id
  location       = "global"
  retention_days = 30
  bucket_id      = "developer-activity-logs"

  # Add this line to wait for billing to stabilize
  depends_on = [time_sleep.wait_for_billing_sync]

  depends_on = [time_sleep.wait_for_billing_sync]

}

resource "google_logging_project_bucket_config" "developer_logs" {
  project        = google_project.dev_project.project_id
  location       = "global"
  retention_days = 30
  bucket_id      = "developer-activity-logs"

  # ADD THIS: Forces Terraform to wait for the 60s billing sync
  depends_on = [time_sleep.wait_for_billing_sync]
}



resource "google_project_iam_member" "developer_monitoring" {
  for_each = toset([
    "roles/logging.viewer",
    "roles/cloudtrace.user"
  ])

  project = google_project.dev_project.project_id
  role    = each.key

  # CHANGE THIS: Use your actual variable or the hardcoded group email
  member = "group:developers@describedata.ai" 
}

# 4. Optional: Create a Log-Based Metric
# This tracks how many "Error" logs your AI agents are producing.
resource "google_logging_metric" "agent_errors" {
  project = google_project.dev_project.project_id
  name    = "ai_agent/error_count"
  filter  = "resource.type=\"cloud_run_revision\" severity>=ERROR"
  
  metric_descriptor {
    metric_kind = "DELTA"
    value_type  = "INT64"
  }
}
