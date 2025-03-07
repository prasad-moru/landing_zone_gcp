# Create the default node pool for general workloads
resource "google_container_node_pool" "default" {
  name               = "default-pool"
  project            = var.project_id
  location           = var.region
  cluster            = var.cluster_name
  initial_node_count = var.default_node_count

  # Enable autoscaling
  autoscaling {
    min_node_count = max(1, var.default_node_count - 2)
    max_node_count = var.default_node_count + 5
  }

  # Enable auto-repair and auto-upgrade
  management {
    auto_repair  = true
    auto_upgrade = true
  }

  # Default node configuration
  node_config {
    machine_type = var.node_machine_type
    disk_size_gb = var.node_disk_size_gb
    disk_type    = var.node_disk_type
    
    # Metadata to enable OS login
    metadata = {
      "disable-legacy-endpoints" = "true"
    }

    # Labels for the nodes
    labels = {
      "env"  = "production"
      "pool" = "default"
    }

    # Taints to prevent workloads without specific tolerations
    # from being scheduled on these nodes
    taint = {}

    # Service account with minimal permissions
    service_account = google_service_account.node_service_account.email

    # OAuth scopes
    oauth_scopes = [
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
      "https://www.googleapis.com/auth/servicecontrol",
      "https://www.googleapis.com/auth/service.management.readonly",
      "https://www.googleapis.com/auth/trace.append"
    ]

    # Enable workload identity
    workload_metadata_config {
      mode = "GKE_METADATA"
    }

    # Enable secure boot
    shielded_instance_config {
      enable_secure_boot          = true
      enable_integrity_monitoring = true
    }
  }

  # Upgrade settings
  upgrade_settings {
    max_surge       = 1
    max_unavailable = 0
  }
}

# Create a specialized node pool for microservices
resource "google_container_node_pool" "microservices" {
  count              = var.create_microservices_node_pool ? 1 : 0
  name               = "microservices-pool"
  project            = var.project_id
  location           = var.region
  cluster            = var.cluster_name
  initial_node_count = var.microservices_node_count

  # Enable autoscaling
  autoscaling {
    min_node_count = max(1, var.microservices_node_count - 2)
    max_node_count = var.microservices_node_count + 10 # Allow more scaling for microservices
  }

  # Enable auto-repair and auto-upgrade
  management {
    auto_repair  = true
    auto_upgrade = true
  }

  # Microservices node configuration
  node_config {
    machine_type = var.microservices_machine_type
    disk_size_gb = var.node_disk_size_gb
    disk_type    = var.node_disk_type

    # Metadata to enable OS login
    metadata = {
      "disable-legacy-endpoints" = "true"
    }

    # Labels for the nodes
    labels = {
      "env"  = "production"
      "pool" = "microservices"
      "workload" = "microservices"
    }

    # Taints to ensure only microservices can be scheduled
    taint {
      key    = "workload"
      value  = "microservices"
      effect = "PREFER_NO_SCHEDULE"
    }

    # Service account with minimal permissions
    service_account = google_service_account.node_service_account.email

    # OAuth scopes
    oauth_scopes = [
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
      "https://www.googleapis.com/auth/servicecontrol",
      "https://www.googleapis.com/auth/service.management.readonly",
      "https://www.googleapis.com/auth/trace.append"
    ]

    # Enable workload identity
    workload_metadata_config {
      mode = "GKE_METADATA"
    }

    # Enable secure boot
    shielded_instance_config {
      enable_secure_boot          = true
      enable_integrity_monitoring = true
    }
  }

  # Upgrade settings
  upgrade_settings {
    max_surge       = 1
    max_unavailable = 0
  }
}

# Create a specialized node pool for OpenSearch
resource "google_container_node_pool" "opensearch" {
  count              = var.create_opensearch_node_pool ? 1 : 0
  name               = "opensearch-pool"
  project            = var.project_id
  location           = var.region
  cluster            = var.cluster_name
  initial_node_count = var.opensearch_node_count

  # Enable autoscaling
  autoscaling {
    min_node_count = var.opensearch_node_count    # Keep minimum nodes stable for OpenSearch
    max_node_count = var.opensearch_node_count + 3
  }

  # Enable auto-repair but be cautious with auto-upgrade for data workloads
  management {
    auto_repair  = true
    auto_upgrade = true
  }

  # OpenSearch node configuration
  node_config {
    machine_type = var.opensearch_machine_type  # High memory machine for OpenSearch
    disk_size_gb = 200  # More disk space for OpenSearch data
    disk_type    = "pd-ssd"  # SSD for better performance

    # Metadata to enable OS login
    metadata = {
      "disable-legacy-endpoints" = "true"
    }

    # Labels for the nodes
    labels = {
      "env"  = "production"
      "pool" = "opensearch"
      "workload" = "opensearch"
    }

    # Taints to ensure only OpenSearch can be scheduled
    taint {
      key    = "workload"
      value  = "opensearch"
      effect = "PREFER_NO_SCHEDULE"
    }

    # Service account with minimal permissions
    service_account = google_service_account.node_service_account.email

    # OAuth scopes
    oauth_scopes = [
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
      "https://www.googleapis.com/auth/servicecontrol",
      "https://www.googleapis.com/auth/service.management.readonly",
      "https://www.googleapis.com/auth/trace.append"
    ]

    # Enable workload identity
    workload_metadata_config {
      mode = "GKE_METADATA"
    }

    # Enable secure boot
    shielded_instance_config {
      enable_secure_boot          = true
      enable_integrity_monitoring = true
    }
  }

  # Upgrade settings - more conservative for data workloads
  upgrade_settings {
    max_surge       = 1
    max_unavailable = 0
  }
}

# Create service account for nodes
resource "google_service_account" "node_service_account" {
  account_id   = "gke-node-sa"
  display_name = "GKE Node Service Account"
  project      = var.project_id
}

# Grant necessary permissions to the service account
resource "google_project_iam_member" "node_sa_log_writer" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.node_service_account.email}"
}

resource "google_project_iam_member" "node_sa_metric_writer" {
  project = var.project_id
  role    = "roles/monitoring.metricWriter"
  member  = "serviceAccount:${google_service_account.node_service_account.email}"
}

resource "google_project_iam_member" "node_sa_monitoring_viewer" {
  project = var.project_id
  role    = "roles/monitoring.viewer"
  member  = "serviceAccount:${google_service_account.node_service_account.email}"
}

resource "google_project_iam_member" "node_sa_resource_metadata_writer" {
  project = var.project_id
  role    = "roles/stackdriver.resourceMetadata.writer"
  member  = "serviceAccount:${google_service_account.node_service_account.email}"
}

resource "google_project_iam_member" "node_sa_object_viewer" {
  project = var.project_id
  role    = "roles/storage.objectViewer"
  member  = "serviceAccount:${google_service_account.node_service_account.email}"
}