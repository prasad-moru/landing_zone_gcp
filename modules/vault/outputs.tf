output "vault_namespace" {
  description = "The namespace where Vault is deployed"
  value       = kubernetes_namespace.vault.metadata[0].name
}

output "vault_address" {
  description = "The internal address for Vault"
  value       = "http://vault-internal.${kubernetes_namespace.vault.metadata[0].name}.svc.cluster.local:8200"
}

output "vault_service_account" {
  description = "The service account used by Vault"
  value       = google_service_account.vault_sa.email
}

output "postgres_instance_name" {
  description = "The name of the PostgreSQL instance"
  value       = google_sql_database_instance.vault_postgres.name
}

output "postgres_connection_name" {
  description = "The connection name of the PostgreSQL instance"
  value       = google_sql_database_instance.vault_postgres.connection_name
}

output "postgres_private_ip" {
  description = "The private IP address of the PostgreSQL instance"
  value       = google_sql_database_instance.vault_postgres.private_ip_address
}

output "kms_key_ring" {
  description = "The KMS key ring used for auto-unsealing"
  value       = google_kms_key_ring.vault.name
}

output "kms_crypto_key" {
  description = "The KMS crypto key used for auto-unsealing"
  value       = google_kms_crypto_key.vault.name
}

output "vault_init_secret" {
  description = "The Kubernetes secret containing Vault initialization data"
  value       = "vault-init"
}