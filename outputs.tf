output "vpc_network" {
  description = "The VPC network created"
  value       = module.network.network_id
}

output "vpc_subnet" {
  description = "The subnet created"
  value       = module.network.subnet_id
}

output "cluster_name" {
  description = "GKE cluster name"
  value       = module.gke-cluster.name
}

output "cluster_id" {
  description = "GKE cluster ID"
  value       = module.gke-cluster.id
}

output "cluster_endpoint" {
  description = "GKE cluster endpoint"
  value       = module.gke-cluster.endpoint
  sensitive   = true
}

output "cluster_ca_certificate" {
  description = "GKE cluster CA certificate"
  value       = module.gke-cluster.ca_certificate
  sensitive   = true
}

output "node_pools" {
  description = "List of node pools created"
  value       = module.node-pools.node_pools
}

output "ingress_ip" {
  description = "IP address of the Ingress controller"
  value       = module.ingress.ingress_ip
}

output "vault_address" {
  description = "HashiCorp Vault address"
  value       = var.create_vault_infrastructure ? module.vault[0].vault_address : null
}

output "postgres_connection_name" {
  description = "PostgreSQL instance connection name"
  value       = var.create_vault_infrastructure ? module.vault[0].postgres_connection_name : null
}

output "kubectl_command" {
  description = "Command to configure kubectl"
  value       = "gcloud container clusters get-credentials ${module.gke-cluster.name} --region ${var.region} --project ${var.project_id}"
}