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

variable "default_node_count" {
  description = "Initial number of nodes in the default node pool"
  type        = number
  default     = 3
}

variable "node_machine_type" {
  description = "The machine type for the default node pool"
  type        = string
  default     = "e2-standard-4"
}

variable "node_disk_size_gb" {
  description = "The disk size for nodes in GB"
  type        = number
  default     = 100
}

variable "node_disk_type" {
  description = "The disk type for nodes"
  type        = string
  default     = "pd-standard"
}

variable "create_microservices_node_pool" {
  description = "Whether to create a specialized node pool for microservices"
  type        = bool
  default     = true
}

variable "microservices_node_count" {
  description = "Initial number of nodes in the microservices node pool"
  type        = number
  default     = 3
}

variable "microservices_machine_type" {
  description = "The machine type for the microservices node pool"
  type        = string
  default     = "e2-standard-4"
}

variable "create_opensearch_node_pool" {
  description = "Whether to create a specialized node pool for OpenSearch"
  type        = bool
  default     = true
}

variable "opensearch_node_count" {
  description = "Initial number of nodes in the OpenSearch node pool"
  type        = number
  default     = 3
}

variable "opensearch_machine_type" {
  description = "The machine type for the OpenSearch node pool"
  type        = string
  default     = "e2-highmem-4"
}