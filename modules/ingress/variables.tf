variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "cluster_name" {
  description = "The name of the GKE cluster"
  type        = string
}

variable "cluster_location" {
  description = "The location of the GKE cluster"
  type        = string
}

variable "microservices_namespace" {
  description = "The namespace for microservices"
  type        = string
  default     = "microservices"
}

variable "network_id" {
  description = "The network ID for firewall rules"
  type        = string
  default     = ""
}