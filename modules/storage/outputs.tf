output "standard_ssd_storage_class" {
  description = "The name of the standard SSD storage class"
  value       = kubernetes_storage_class.standard_ssd.metadata[0].name
}

output "premium_ssd_storage_class" {
  description = "The name of the premium SSD storage class"
  value       = kubernetes_storage_class.premium_ssd.metadata[0].name
}

output "standard_hdd_storage_class" {
  description = "The name of the standard HDD storage class"
  value       = kubernetes_storage_class.standard_hdd.metadata[0].name
}

output "opensearch_storage_class" {
  description = "The name of the OpenSearch storage class"
  value       = kubernetes_storage_class.opensearch_storage.metadata[0].name
}

output "local_ssd_storage_class" {
  description = "The name of the local SSD storage class"
  value       = kubernetes_storage_class.local_ssd.metadata[0].name
}

output "filestore_storage_class" {
  description = "The name of the Filestore storage class"
  value       = kubernetes_storage_class.filestore.metadata[0].name
}

output "shared_volume_name" {
  description = "The name of the shared persistent volume"
  value       = kubernetes_persistent_volume.shared_volume.metadata[0].name
}

output "microservices_shared_pvc" {
  description = "The name of the microservices shared PVC"
  value       = kubernetes_persistent_volume_claim.microservices_shared.metadata[0].name
}