# Create storage classes for different performance needs

# Default SSD storage class
resource "kubernetes_storage_class" "standard_ssd" {
  metadata {
    name = "standard-ssd"
    annotations = {
      "storageclass.kubernetes.io/is-default-class" = "true"
    }
  }
  storage_provisioner = "pd.csi.storage.gke.io"
  reclaim_policy      = "Delete"
  parameters = {
    type = "pd-ssd"
  }
  volume_binding_mode = "WaitForFirstConsumer"
}

# Premium SSD storage class for high-performance workloads
resource "kubernetes_storage_class" "premium_ssd" {
  metadata {
    name = "premium-ssd"
  }
  storage_provisioner = "pd.csi.storage.gke.io"
  reclaim_policy      = "Delete"
  parameters = {
    type       = "pd-ssd"
    replication-type = "regional-pd"
  }
  volume_binding_mode = "WaitForFirstConsumer"
}

# Standard HDD storage class for low-cost, non-critical storage
resource "kubernetes_storage_class" "standard_hdd" {
  metadata {
    name = "standard-hdd"
  }
  storage_provisioner = "pd.csi.storage.gke.io"
  reclaim_policy      = "Delete"
  parameters = {
    type = "pd-standard"
  }
  volume_binding_mode = "WaitForFirstConsumer"
}

# Storage class optimized for OpenSearch
resource "kubernetes_storage_class" "opensearch_storage" {
  metadata {
    name = "opensearch-storage"
  }
  storage_provisioner = "pd.csi.storage.gke.io"
  reclaim_policy      = "Delete"
  parameters = {
    type = "pd-ssd"
  }
  volume_binding_mode = "WaitForFirstConsumer"

  allowed_topologies {
    match_label_expressions {
      key      = "topology.kubernetes.io/zone"
      values   = ["${var.region}-a", "${var.region}-b", "${var.region}-c"]
    }
  }
}

# Local SSD storage class for ephemeral, high-performance storage
resource "kubernetes_storage_class" "local_ssd" {
  metadata {
    name = "local-ssd"
  }
  storage_provisioner = "pd.csi.storage.gke.io"
  reclaim_policy      = "Delete"
  parameters = {
    type = "pd-ssd"
    provisioner = "kubernetes.io/no-provisioner"
  }
  volume_binding_mode = "WaitForFirstConsumer"
}

# Filestore storage class for shared file systems
resource "kubernetes_storage_class" "filestore" {
  metadata {
    name = "filestore"
  }
  storage_provisioner = "filestore.csi.storage.gke.io"
  reclaim_policy      = "Delete"
  parameters = {
    tier = "standard"
  }
  volume_binding_mode = "Immediate"
}

# Create priority classes for storage-related workloads
resource "kubernetes_priority_class" "storage_critical" {
  metadata {
    name = "storage-critical"
  }
  value = 1000000
  global_default = false
  description = "This priority class should be used for storage-related pods that must never be evicted."
}

resource "kubernetes_priority_class" "storage_high" {
  metadata {
    name = "storage-high"
  }
  value = 900000
  global_default = false
  description = "This priority class should be used for storage-related pods that should rarely be evicted."
}

# Create persistent volumes for applications that need dedicated storage
resource "kubernetes_persistent_volume" "shared_volume" {
  metadata {
    name = "shared-volume"
  }
  spec {
    capacity = {
      storage = "100Gi"
    }
    access_modes = ["ReadWriteMany"]
    persistent_volume_reclaim_policy = "Retain"
    storage_class_name = kubernetes_storage_class.filestore.metadata[0].name
    persistent_volume_source {
      csi {
        driver = "filestore.csi.storage.gke.io"
        volume_handle = "projects/${var.project_id}/locations/${var.region}/instances/shared-filestore/volumes/shared-volume"
      }
    }
  }
}

# Create storage configuration for OpenSearch
resource "kubernetes_config_map" "opensearch_storage_config" {
  metadata {
    name = "opensearch-storage-config"
    namespace = var.opensearch_namespace
  }

  data = {
    "storage.yml" = <<-EOT
      path:
        data: /usr/share/opensearch/data
        logs: /usr/share/opensearch/logs
      repository:
        url:
          allowed_urls: ["gs://${var.project_id}-opensearch-backups/*"]
    EOT
  }
}

# Create a persistent volume claim for microservices shared storage
resource "kubernetes_persistent_volume_claim" "microservices_shared" {
  metadata {
    name = "microservices-shared"
    namespace = var.microservices_namespace
  }
  spec {
    access_modes = ["ReadWriteMany"]
    storage_class_name = kubernetes_storage_class.filestore.metadata[0].name
    resources {
      requests = {
        storage = "50Gi"
      }
    }
  }
}