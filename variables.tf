# Project variables
variable "project_id" {
  description = "The GCP project ID to deploy resources"
  type        = string
}

variable "region" {
  description = "The GCP region to deploy resources"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "The GCP zone to deploy resources"
  type        = string
  default     = "us-central1-a"
}

# Network variables
variable "network_name" {
  description = "Name of the VPC network"
  type        = string
  default     = "gke-vpc-network"
}

variable "subnet_name" {
  description = "Name of the subnet for GKE cluster"
  type        = string
  default     = "gke-subnet"
}

variable "subnet_cidr" {
  description = "CIDR range for the subnet"
  type        = string
  default     = "10.0.0.0/16"
}

variable "pod_cidr" {
  description = "CIDR range for pods"
  type        = string
  default     = "10.1.0.0/16"
}

variable "service_cidr" {
  description = "CIDR range for services"
  type        = string
  default     = "10.2.0.0/16"
}

# GKE Cluster variables
variable "cluster_name" {
  description = "Name of the GKE cluster"
  type        = string
  default     = "gke-prod-cluster"
}

variable "cluster_description" {
  description = "Description of the cluster"
  type        = string
  default     = "Production GKE cluster"
}

variable "kubernetes_version" {
  description = "Kubernetes version to use in the cluster"
  type        = string
  default     = "1.25"
}

variable "enable_private_endpoint" {
  description = "When true, the cluster's endpoint is not provisioned with an IP and can only be accessed by private IP"
  type        = bool
  default     = true
}

variable "enable_private_nodes" {
  description = "When true, nodes will have private IPs only"
  type        = bool
  default     = true
}

variable "master_ipv4_cidr_block" {
  description = "CIDR block for the masters"
  type        = string
  default     = "172.16.0.0/28"
}

# Node pool variables
variable "default_node_count" {
  description = "Number of nodes in the default node pool"
  type        = number
  default     = 3
}

variable "node_machine_type" {
  description = "Default machine type for the nodes"
  type        = string
  default     = "e2-standard-4"
}

variable "node_disk_size_gb" {
  description = "Default disk size for the nodes in GB"
  type        = number
  default     = 100
}

variable "node_disk_type" {
  description = "Default disk type for the nodes"
  type        = string
  default     = "pd-standard"
}

# Specialized node pools
variable "create_microservices_node_pool" {
  description = "Whether to create a specialized node pool for microservices"
  type        = bool
  default     = true
}

variable "microservices_node_count" {
  description = "Number of nodes in the microservices node pool"
  type        = number
  default     = 3
}

variable "microservices_machine_type" {
  description = "Machine type for the microservices nodes"
  type        = string
  default     = "e2-standard-4"
}

variable "create_opensearch_node_pool" {
  description = "Whether to create a specialized node pool for OpenSearch"
  type        = bool
  default     = true
}

variable "opensearch_node_count" {
  description = "Number of nodes in the OpenSearch node pool"
  type        = number
  default     = 3
}

variable "opensearch_machine_type" {
  description = "Machine type for the OpenSearch nodes"
  type        = string
  default     = "e2-highmem-4"
}

# Vault PostgreSQL variables
variable "create_vault_infrastructure" {
  description = "Whether to create HashiCorp Vault with PostgreSQL backend"
  type        = bool
  default     = true
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

# Monitoring variables
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