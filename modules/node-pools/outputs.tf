output "default_node_pool_name" {
  description = "The name of the default node pool"
  value       = google_container_node_pool.default.name
}

output "default_node_pool_id" {
  description = "The ID of the default node pool"
  value       = google_container_node_pool.default.id
}

output "microservices_node_pool_name" {
  description = "The name of the microservices node pool"
  value       = var.create_microservices_node_pool ? google_container_node_pool.microservices[0].name : null
}

output "microservices_node_pool_id" {
  description = "The ID of the microservices node pool"
  value       = var.create_microservices_node_pool ? google_container_node_pool.microservices[0].id : null
}

output "opensearch_node_pool_name" {
  description = "The name of the OpenSearch node pool"
  value       = var.create_opensearch_node_pool ? google_container_node_pool.opensearch[0].name : null
}

output "opensearch_node_pool_id" {
  description = "The ID of the OpenSearch node pool"
  value       = var.create_opensearch_node_pool ? google_container_node_pool.opensearch[0].id : null
}

output "node_service_account" {
  description = "The service account used by the nodes"
  value       = google_service_account.node_service_account.email
}

output "node_pools" {
  description = "List of node pools created"
  value = {
    "default" = {
      name        = google_container_node_pool.default.name
      machine_type = var.node_machine_type
      disk_size_gb = var.node_disk_size_gb
      initial_node_count = var.default_node_count
    }
    "microservices" = var.create_microservices_node_pool ? {
      name        = google_container_node_pool.microservices[0].name
      machine_type = var.microservices_machine_type
      disk_size_gb = var.node_disk_size_gb
      initial_node_count = var.microservices_node_count
    } : null
    "opensearch" = var.create_opensearch_node_pool ? {
      name        = google_container_node_pool.opensearch[0].name
      machine_type = var.opensearch_machine_type
      disk_size_gb = 200
      initial_node_count = var.opensearch_node_count
    } : null
  }
}