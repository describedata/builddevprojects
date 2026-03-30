terraform {
  backend "gcs" {
    bucket  = " audit-terraform-seed-state" # Create this manually once in your seed project
    prefix  = "terraform/state/ai-dev"
  }
}