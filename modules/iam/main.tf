# Create a service account for Workload Identity
resource "google_service_account" "gke_sa" {
  account_id   = "gke-workload-identity-sa"
  display_name = "GKE Workload Identity Service Account"
  project      = var.project_id
}

# Grant necessary permissions to the service account
resource "google_project_iam_member" "gke_sa_metric_writer" {
  project = var.project_id
  role    = "roles/monitoring.metricWriter"
  member  = "serviceAccount:${google_service_account.gke_sa.email}"
}

resource "google_project_iam_member" "gke_sa_log_writer" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.gke_sa.email}"
}

resource "google_project_iam_member" "gke_sa_monitoring_viewer" {
  project = var.project_id
  role    = "roles/monitoring.viewer"
  member  = "serviceAccount:${google_service_account.gke_sa.email}"
}

# Create a service account for microservices
resource "google_service_account" "microservices_sa" {
  account_id   = "microservices-sa"
  display_name = "Microservices Service Account"
  project      = var.project_id
}

# Grant permissions for service mesh and monitoring
resource "google_project_iam_member" "microservices_sa_metric_writer" {
  project = var.project_id
  role    = "roles/monitoring.metricWriter"
  member  = "serviceAccount:${google_service_account.microservices_sa.email}"
}

resource "google_project_iam_member" "microservices_sa_log_writer" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.microservices_sa.email}"
}

# Create a service account for OpenSearch
resource "google_service_account" "opensearch_sa" {
  account_id   = "opensearch-sa"
  display_name = "OpenSearch Service Account"
  project      = var.project_id
}

# Grant necessary storage permissions for OpenSearch
resource "google_project_iam_member" "opensearch_sa_storage_admin" {
  project = var.project_id
  role    = "roles/storage.admin"
  member  = "serviceAccount:${google_service_account.opensearch_sa.email}"
}

resource "google_project_iam_member" "opensearch_sa_log_writer" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.opensearch_sa.email}"
}

# Set up IAM policy for Workload Identity
resource "google_service_account_iam_binding" "gke_sa_workload_identity" {
  service_account_id = google_service_account.gke_sa.name
  role               = "roles/iam.workloadIdentityUser"
  members = [
    "serviceAccount:${var.project_id}.svc.id.goog[kube-system/default]"
  ]
}

resource "google_service_account_iam_binding" "microservices_sa_workload_identity" {
  service_account_id = google_service_account.microservices_sa.name
  role               = "roles/iam.workloadIdentityUser"
  members = [
    "serviceAccount:${var.project_id}.svc.id.goog[default/default]",
    "serviceAccount:${var.project_id}.svc.id.goog[microservices/default]"
  ]
}

resource "google_service_account_iam_binding" "opensearch_sa_workload_identity" {
  service_account_id = google_service_account.opensearch_sa.name
  role               = "roles/iam.workloadIdentityUser"
  members = [
    "serviceAccount:${var.project_id}.svc.id.goog[opensearch/default]"
  ]
}

# Create a Kubernetes namespace for microservices
resource "kubernetes_namespace" "microservices" {
  metadata {
    name = "microservices"

    labels = {
      environment = "production"
    }
  }
}

# Create a Kubernetes namespace for OpenSearch
resource "kubernetes_namespace" "opensearch" {
  metadata {
    name = "opensearch"

    labels = {
      environment = "production"
    }
  }
}

# Create Kubernetes service accounts to use with Workload Identity
resource "kubernetes_service_account" "microservices_ksa" {
  metadata {
    name      = "microservices-sa"
    namespace = kubernetes_namespace.microservices.metadata[0].name
    annotations = {
      "iam.gke.io/gcp-service-account" = google_service_account.microservices_sa.email
    }
  }
}

resource "kubernetes_service_account" "opensearch_ksa" {
  metadata {
    name      = "opensearch-sa"
    namespace = kubernetes_namespace.opensearch.metadata[0].name
    annotations = {
      "iam.gke.io/gcp-service-account" = google_service_account.opensearch_sa.email
    }
  }
}

# Create role bindings for the service accounts
resource "kubernetes_role_binding" "microservices_rb" {
  metadata {
    name      = "microservices-rb"
    namespace = kubernetes_namespace.microservices.metadata[0].name
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "edit"
  }
  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.microservices_ksa.metadata[0].name
    namespace = kubernetes_namespace.microservices.metadata[0].name
  }
}

resource "kubernetes_role_binding" "opensearch_rb" {
  metadata {
    name      = "opensearch-rb"
    namespace = kubernetes_namespace.opensearch.metadata[0].name
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "edit"
  }
  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.opensearch_ksa.metadata[0].name
    namespace = kubernetes_namespace.opensearch.metadata[0].name
  }
}

# Create a network policy for the microservices namespace
resource "kubernetes_network_policy" "microservices_network_policy" {
  metadata {
    name      = "microservices-network-policy"
    namespace = kubernetes_namespace.microservices.metadata[0].name
  }

  spec {
    pod_selector {}

    ingress {
      from {
        namespace_selector {
          match_labels = {
            "kubernetes.io/metadata.name" = "microservices"
          }
        }
      }
      from {
        namespace_selector {
          match_labels = {
            "kubernetes.io/metadata.name" = "kube-system"
          }
        }
      }
    }

    policy_types = ["Ingress", "Egress"]
    
    egress {}
  }
}