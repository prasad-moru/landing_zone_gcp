# Project variables
project_id                = "k8s-workloads-452815"
region                    = "us-central1"
zone                      = "us-central1-a"

# Network variables
network_name              = "gke-prod-network"
subnet_name               = "gke-prod-subnet"
subnet_cidr               = "10.0.0.0/16"
pod_cidr                  = "10.1.0.0/16"
service_cidr              = "10.2.0.0/16"

# GKE Cluster variables
cluster_name              = "gke-prod-cluster"
cluster_description       = "Production GKE cluster with microservices support"
kubernetes_version        = "1.29"
enable_private_endpoint   = true
enable_private_nodes      = true
master_ipv4_cidr_block    = "172.16.0.0/28"

# Node pool variables
default_node_count        = 3
node_machine_type         = "e2-standard-4"
node_disk_size_gb         = 100
node_disk_type            = "pd-standard"

# Microservices node pool
create_microservices_node_pool = true
microservices_node_count  = 3
microservices_machine_type = "e2-standard-4"

# OpenSearch node pool
create_opensearch_node_pool = true
opensearch_node_count     = 3
opensearch_machine_type   = "e2-highmem-4"

# Vault PostgreSQL variables
create_vault_infrastructure = true
postgres_tier             = "db-custom-2-7680"
postgres_ha               = true

# Monitoring variables
enable_monitoring         = true
enable_logging            = true