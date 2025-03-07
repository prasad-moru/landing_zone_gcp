terraform {
  backend "gcs" {
    bucket  = "tf-state-gke-prod-cluster"
    prefix  = "terraform/state"
  }
  
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.40.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 4.40.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.16.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.7.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.4.0"
    }
  }
  
  required_version = ">= 1.3.0"
}