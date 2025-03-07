variable "project_id" {
  description = "The GCP project ID"
  type        = string
  default     = ""
}

variable "region" {
  description = "The GCP region where resources are created"
  type        = string
  default     = "us-central1"
}

variable "opensearch_namespace" {
  description = "The Kubernetes namespace for OpenSearch"
  type        = string
  default     = "opensearch"
}

variable "microservices_namespace" {
  description = "The Kubernetes namespace for microservices"
  type        = string
  default     = "microservices"
}