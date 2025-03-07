output "ingress_namespace" {
  description = "The namespace where ingress resources are deployed"
  value       = kubernetes_namespace.ingress.metadata[0].name
}

output "ingress_class" {
  description = "The ingress class name"
  value       = "nginx"
}

output "ingress_ip" {
  description = "The external IP address of the ingress controller"
  value       = data.kubernetes_service.ingress_nginx.status.0.load_balancer.0.ingress.0.ip
}

output "ingress_hostname" {
  description = "The hostname of the ingress controller if applicable"
  value       = try(data.kubernetes_service.ingress_nginx.status.0.load_balancer.0.ingress.0.hostname, null)
}

output "cert_manager_installed" {
  description = "Whether cert-manager has been installed"
  value       = true
}

output "cluster_issuer_prod" {
  description = "The name of the production Let's Encrypt cluster issuer"
  value       = "letsencrypt-prod"
}

output "cluster_issuer_staging" {
  description = "The name of the staging Let's Encrypt cluster issuer"
  value       = "letsencrypt-staging"
}

output "google_managed_cert_id" {
  description = "The ID of the Google-managed certificate"
  value       = google_compute_managed_ssl_certificate.default.id
}