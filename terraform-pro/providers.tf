terraform {
  required_version = ">= 1.5.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0" # Latest stable for 2026
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 6.0"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.11"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }

  # Replace with your actual GCS bucket created in the seed step
  backend "gcs" {
    bucket = "audit-terraform-seed-state" 
    prefix = "terraform/state/ai-dev"
  }
}

# Standard Provider
provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

# Beta Provider (Required for Identity Groups and some Vertex AI features)
provider "google-beta" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

# Time Provider (Required for the 60s Billing Sync timer)
provider "time" {}

# Random Provider (Required for unique project suffixes)
provider "random" {}