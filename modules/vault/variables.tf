variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "region" {
  description = "The GCP region to deploy resources"
  type        = string
}

variable "cluster_name" {
  description = "The name of the GKE cluster"
  type        = string
}

variable "network_id" {
  description = "The VPC network ID"
  type        = string
}

variable "subnet_id" {
  description = "The subnet ID"
  type        = string
}

variable "postgres_tier" {
  description = "The tier for the PostgreSQL instance"
  type        = string
  default     = "db-custom-2-7680"
}

variable "postgres_ha" {
  description = "Whether to enable high availability for PostgreSQL"
  type        = bool
  default     = true
}