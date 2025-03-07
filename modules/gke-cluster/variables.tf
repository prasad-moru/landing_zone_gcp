variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "region" {
  description = "The GCP region to deploy resources"
  type        = string
}

variable "cluster_name" {
  description = "Name of the GKE cluster"
  type        = string
}

variable "cluster_description" {
  description = "Description of the cluster"
  type        = string
  default     = "Production GKE cluster"
}

variable "kubernetes_version" {
  description = "Kubernetes version to use in the cluster"
  type        = string
}

variable "network_id" {
  description = "The VPC network self-link to which the cluster is connected"
  type        = string
}

variable "subnet_id" {
  description = "The subnet self-link to which the cluster is connected"
  type        = string
}

variable "master_ipv4_cidr_block" {
  description = "The IP range in CIDR notation for the master network"
  type        = string
}

variable "enable_private_endpoint" {
  description = "Whether the master's internal IP address is used as the cluster endpoint"
  type        = bool
  default     = true
}

variable "enable_private_nodes" {
  description = "Whether nodes have internal IP addresses only"
  type        = bool
  default     = true
}

variable "pod_cidr" {
  description = "CIDR range for pods"
  type        = string
}

variable "service_cidr" {
  description = "CIDR range for services"
  type        = string
}

variable "enable_monitoring" {
  description = "Whether to enable Cloud Monitoring"
  type        = bool
  default     = true
}

variable "enable_logging" {
  description = "Whether to enable Cloud Logging"
  type        = bool
  default     = true
}