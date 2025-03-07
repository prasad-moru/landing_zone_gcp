output "network_id" {
  description = "The ID of the VPC network"
  value       = google_compute_network.vpc_network.id
}

output "network_name" {
  description = "The name of the VPC network"
  value       = google_compute_network.vpc_network.name
}

output "network_self_link" {
  description = "The self-link of the VPC network"
  value       = google_compute_network.vpc_network.self_link
}

output "subnet_id" {
  description = "The ID of the subnet"
  value       = google_compute_subnetwork.subnet.id
}

output "subnet_name" {
  description = "The name of the subnet"
  value       = google_compute_subnetwork.subnet.name
}

output "subnet_self_link" {
  description = "The self-link of the subnet"
  value       = google_compute_subnetwork.subnet.self_link
}

output "pod_cidr_name" {
  description = "The name of the secondary IP range for pods"
  value       = "pod-ranges"
}

output "service_cidr_name" {
  description = "The name of the secondary IP range for services"
  value       = "service-ranges"
}

output "nat_ip" {
  description = "The NAT IP addresses"
  value       = google_compute_router_nat.nat.nat_ips
}