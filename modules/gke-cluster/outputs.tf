output "name" {
  description = "The name of the GKE cluster"
  value       = google_container_cluster.primary.name
}

output "id" {
  description = "The ID of the GKE cluster"
  value       = google_container_cluster.primary.id
}

output "endpoint" {
  description = "The IP address of the GKE cluster master"
  value       = google_container_cluster.primary.endpoint
  sensitive   = true
}

output "location" {
  description = "The location of the GKE cluster"
  value       = google_container_cluster.primary.location
}

output "ca_certificate" {
  description = "The CA certificate for the GKE cluster"
  value       = google_container_cluster.primary.master_auth.0.cluster_ca_certificate
  sensitive   = true
}

output "self_link" {
  description = "The server-defined URL for the GKE cluster"
  value       = google_container_cluster.primary.self_link
}

output "master_version" {
  description = "The Kubernetes master version"
  value       = google_container_cluster.primary.master_version
}

output "workload_identity_config" {
  description = "The workload identity configuration for the cluster"
  value       = google_container_cluster.primary.workload_identity_config[0].workload_pool
}