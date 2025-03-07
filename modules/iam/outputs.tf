output "gke_service_account" {
  description = "The email of the GKE service account"
  value       = google_service_account.gke_sa.email
}

output "microservices_service_account" {
  description = "The email of the microservices service account"
  value       = google_service_account.microservices_sa.email
}

output "opensearch_service_account" {
  description = "The email of the OpenSearch service account"
  value       = google_service_account.opensearch_sa.email
}

output "microservices_namespace" {
  description = "The name of the microservices namespace"
  value       = kubernetes_namespace.microservices.metadata[0].name
}

output "opensearch_namespace" {
  description = "The name of the OpenSearch namespace"
  value       = kubernetes_namespace.opensearch.metadata[0].name
}