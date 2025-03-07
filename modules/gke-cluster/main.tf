# Get information about the subnet to use for the GKE cluster
data "google_compute_subnetwork" "subnet" {
  name    = element(split("/", var.subnet_id), length(split("/", var.subnet_id)) - 1)
  project = var.project_id
  region  = var.region
}

# Create the GKE cluster
resource "google_container_cluster" "primary" {
  name        = var.cluster_name
  description = var.cluster_description
  project     = var.project_id
  location    = var.region

  # We can't create a cluster with no node pool defined, but we want to only use
  # separately managed node pools. So we create the smallest possible default
  # node pool and immediately delete it.
  remove_default_node_pool = true
  initial_node_count       = 1

  # Specify network configuration
  network    = var.network_id
  subnetwork = var.subnet_id

  # IP allocation policy
  ip_allocation_policy {
    cluster_secondary_range_name  = "pod-ranges"
    services_secondary_range_name = "service-ranges"
  }

  # Enable private cluster settings
  private_cluster_config {
    enable_private_nodes    = var.enable_private_nodes
    enable_private_endpoint = var.enable_private_endpoint
    master_ipv4_cidr_block  = var.master_ipv4_cidr_block

    master_global_access_config {
      enabled = true
    }
  }

  # Allow authorized networks if private endpoint is disabled
  dynamic "master_authorized_networks_config" {
    for_each = var.enable_private_endpoint ? [] : [1]
    content {
      cidr_blocks {
        cidr_block   = "0.0.0.0/0"
        display_name = "All"
      }
    }
  }

  # Enable workload identity
  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }

  # Enable network policy (Calico)
  network_policy {
    enabled  = true
    provider = "CALICO"
  }

  # Enable intra-node visibility for better network monitoring
  enable_intranode_visibility = true

  # Enable binary authorization
  binary_authorization {
    evaluation_mode = "PROJECT_SINGLETON_POLICY_ENFORCE"
  }

  # Pod security policy is deprecated, but we'll use it if available
  pod_security_policy_config {
    enabled = false
  }

  # Enable shielded nodes
  enable_shielded_nodes = true

  # Enable autopilot - set to false for standard cluster
  enable_autopilot = false

  # Enable Kubernetes dashboard - disable this as it's deprecated
  # addons_config {
  #   kubernetes_dashboard {
  #     disabled = true
  #   }
  # }

  # Enable network policy
  addons_config {
    network_policy_config {
      disabled = false
    }
    
    http_load_balancing {
      disabled = false
    }
    
    horizontal_pod_autoscaling {
      disabled = false
    }
    
    gcp_filestore_csi_driver_config {
      enabled = true
    }
    
    gce_persistent_disk_csi_driver_config {
      enabled = true
    }
    
    dns_cache_config {
      enabled = true
    }
  }

  # Enable VPA
  vertical_pod_autoscaling {
    enabled = true
  }

  # Enable master region availability
  release_channel {
    channel = "REGULAR"
  }

  # Upgrade settings
  maintenance_policy {
    recurring_window {
      start_time = "2023-01-01T00:00:00Z"
      end_time   = "2023-01-02T00:00:00Z"
      recurrence = "FREQ=WEEKLY;BYDAY=SA,SU"
    }
  }

  # Enable monitoring and logging
  logging_service    = var.enable_logging ? "logging.googleapis.com/kubernetes" : "none"
  monitoring_service = var.enable_monitoring ? "monitoring.googleapis.com/kubernetes" : "none"

  # Node config
  node_config {
    # Specifying an empty oauth scopes list will use the GKE default scopes
    oauth_scopes = [
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
      "https://www.googleapis.com/auth/servicecontrol",
      "https://www.googleapis.com/auth/service.management.readonly",
      "https://www.googleapis.com/auth/trace.append"
    ]

    # Enable workload identity on all nodes
    workload_metadata_config {
      mode = "GKE_METADATA"
    }

    # Enable secure boot for nodes
    shielded_instance_config {
      enable_secure_boot          = true
      enable_integrity_monitoring = true
    }
  }

  # Networking options
  default_max_pods_per_node = 110

  # Networking mode - using VPC-native
  networking_mode = "VPC_NATIVE"

  # Set deletion protection
  deletion_protection = false
}