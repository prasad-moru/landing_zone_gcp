# Create network infrastructure
module "network" {
  source       = "./modules/network"
  project_id   = var.project_id
  region       = var.region
  network_name = var.network_name
  subnet_name  = var.subnet_name
  subnet_cidr  = var.subnet_cidr
  pod_cidr     = var.pod_cidr
  service_cidr = var.service_cidr
}

# Create GKE cluster
module "gke-cluster" {
  source                  = "./modules/gke-cluster"
  project_id              = var.project_id
  region                  = var.region
  cluster_name            = var.cluster_name
  cluster_description     = var.cluster_description
  kubernetes_version      = var.kubernetes_version
  network_id              = module.network.network_id
  subnet_id               = module.network.subnet_id
  master_ipv4_cidr_block  = var.master_ipv4_cidr_block
  enable_private_endpoint = var.enable_private_endpoint
  enable_private_nodes    = var.enable_private_nodes
  pod_cidr                = var.pod_cidr
  service_cidr            = var.service_cidr
  enable_monitoring       = var.enable_monitoring
  enable_logging          = var.enable_logging
}

# Create node pools
module "node-pools" {
  source                        = "./modules/node-pools"
  project_id                    = var.project_id
  region                        = var.region
  cluster_name                  = module.gke-cluster.name
  default_node_count            = var.default_node_count
  node_machine_type             = var.node_machine_type
  node_disk_size_gb             = var.node_disk_size_gb
  node_disk_type                = var.node_disk_type
  create_microservices_node_pool = var.create_microservices_node_pool
  microservices_node_count      = var.microservices_node_count
  microservices_machine_type    = var.microservices_machine_type
  create_opensearch_node_pool   = var.create_opensearch_node_pool
  opensearch_node_count         = var.opensearch_node_count
  opensearch_machine_type       = var.opensearch_machine_type
  
  depends_on = [module.gke-cluster]
}

# Configure IAM roles and bindings
module "iam" {
  source     = "./modules/iam"
  project_id = var.project_id
  cluster_id = module.gke-cluster.id
  
  depends_on = [module.gke-cluster]
}

# Configure storage classes
module "storage" {
  source                = "./modules/storage"
  depends_on            = [module.gke-cluster]
}

# Configure GKE Ingress
module "ingress" {
  source                = "./modules/ingress"
  project_id            = var.project_id
  cluster_name          = module.gke-cluster.name
  cluster_location      = var.region
  
  depends_on            = [module.gke-cluster, module.node-pools]
}

# Conditionally set up HashiCorp Vault with PostgreSQL
module "vault" {
  source                  = "./modules/vault"
  count                   = var.create_vault_infrastructure ? 1 : 0
  project_id              = var.project_id
  region                  = var.region
  cluster_name            = module.gke-cluster.name
  network_id              = module.network.network_id
  subnet_id               = module.network.subnet_id
  postgres_tier           = var.postgres_tier
  postgres_ha             = var.postgres_ha
  
  depends_on              = [module.gke-cluster, module.node-pools]
}