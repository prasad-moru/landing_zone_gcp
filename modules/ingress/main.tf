# Create namespace for ingress resources
resource "kubernetes_namespace" "ingress" {
  metadata {
    name = "ingress-system"
    
    labels = {
      "app.kubernetes.io/name" = "ingress-system"
      "app.kubernetes.io/instance" = "ingress-system"
    }
  }
}

# Create service account for ingress controller
resource "kubernetes_service_account" "ingress_controller" {
  metadata {
    name      = "ingress-controller-sa"
    namespace = kubernetes_namespace.ingress.metadata[0].name
    
    labels = {
      "app.kubernetes.io/name" = "ingress-controller"
      "app.kubernetes.io/instance" = "ingress-controller"
    }
  }
}

# Use Helm to deploy GKE Ingress Controller
resource "helm_release" "ingress_nginx" {
  name       = "ingress-nginx"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  version    = "4.4.0"
  namespace  = kubernetes_namespace.ingress.metadata[0].name
  timeout    = 900

  set {
    name  = "controller.service.type"
    value = "LoadBalancer"
  }

  set {
    name  = "controller.ingressClassResource.name"
    value = "nginx"
  }

  set {
    name  = "controller.ingressClassResource.default"
    value = "true"
  }

  set {
    name  = "controller.replicaCount"
    value = "3"
  }

  set {
    name  = "controller.minAvailable"
    value = "1"
  }

  set {
    name  = "controller.resources.requests.cpu"
    value = "100m"
  }

  set {
    name  = "controller.resources.requests.memory"
    value = "90Mi"
  }

  set {
    name  = "controller.service.externalTrafficPolicy"
    value = "Local"
  }

  set {
    name  = "controller.autoscaling.enabled"
    value = "true"
  }

  set {
    name  = "controller.autoscaling.minReplicas"
    value = "2"
  }

  set {
    name  = "controller.autoscaling.maxReplicas"
    value = "10"
  }

  set {
    name  = "controller.metrics.enabled"
    value = "true"
  }

  set {
    name  = "controller.podAnnotations.prometheus\\.io/scrape"
    value = "true"
    type   = "string"
  }

  set {
    name  = "controller.podAnnotations.prometheus\\.io/port"
    value = "10254"
    type   = "string"
  }

  set {
    name  = "controller.config.use-forwarded-headers"
    value = "true"
  }

  set {
    name  = "controller.config.ssl-redirect"
    value = "true"
  }

  set {
    name  = "controller.config.force-ssl-redirect"
    value = "false"
  }

  set {
    name  = "controller.config.hsts"
    value = "true"
  }

  set {
    name  = "controller.config.hsts-include-subdomains"
    value = "true"
  }

  set {
    name  = "controller.config.hsts-max-age"
    value = "63072000"
  }

  set {
    name  = "controller.config.proxy-buffer-size"
    value = "16k"
  }

  set {
    name  = "controller.config.proxy-body-size"
    value = "10m"
  }

  set {
    name  = "controller.config.server-tokens"
    value = "false"
  }

  set {
    name  = "controller.service.annotations.cloud\\.google\\.com/load-balancer-type"
    value = "External"
    type   = "string"
  }
}

# Create cert-manager for TLS certificate management
resource "helm_release" "cert_manager" {
  name       = "cert-manager"
  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  version    = "v1.10.0"
  namespace  = kubernetes_namespace.ingress.metadata[0].name
  timeout    = 900

  set {
    name  = "installCRDs"
    value = "true"
  }

  set {
    name  = "replicaCount"
    value = "3"
  }

  set {
    name  = "extraArgs"
    value = "{--dns01-recursive-nameservers=8.8.8.8:53\\,1.1.1.1:53}"
  }

  set {
    name  = "prometheus.enabled"
    value = "true"
  }

  set {
    name  = "prometheus.servicemonitor.enabled"
    value = "true"
  }

  set {
    name  = "webhook.replicaCount"
    value = "3"
  }

  set {
    name  = "cainjector.replicaCount"
    value = "3"
  }

  depends_on = [helm_release.ingress_nginx]
}

# Create cluster issuer for Let's Encrypt certificates
resource "kubernetes_manifest" "cluster_issuer_staging" {
  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "ClusterIssuer"
    metadata = {
      name = "letsencrypt-staging"
    }
    spec = {
      acme = {
        email  = "admin@example.com"
        server = "https://acme-staging-v02.api.letsencrypt.org/directory"
        privateKeySecretRef = {
          name = "letsencrypt-staging-account-key"
        }
        solvers = [
          {
            http01 = {
              ingress = {
                class = "nginx"
              }
            }
          }
        ]
      }
    }
  }

  depends_on = [helm_release.cert_manager]
}

resource "kubernetes_manifest" "cluster_issuer_prod" {
  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "ClusterIssuer"
    metadata = {
      name = "letsencrypt-prod"
    }
    spec = {
      acme = {
        email  = "admin@example.com"
        server = "https://acme-v02.api.letsencrypt.org/directory"
        privateKeySecretRef = {
          name = "letsencrypt-prod-account-key"
        }
        solvers = [
          {
            http01 = {
              ingress = {
                class = "nginx"
              }
            }
          }
        ]
      }
    }
  }

  depends_on = [helm_release.cert_manager]
}

# Create ingress rule for microservices API gateway
resource "kubernetes_ingress_v1" "microservices_ingress" {
  metadata {
    name      = "microservices-ingress"
    namespace = var.microservices_namespace

    annotations = {
      "kubernetes.io/ingress.class" = "nginx"
      "cert-manager.io/cluster-issuer" = "letsencrypt-prod"
      "nginx.ingress.kubernetes.io/ssl-redirect" = "true"
      "nginx.ingress.kubernetes.io/proxy-body-size" = "10m"
      "nginx.ingress.kubernetes.io/proxy-buffer-size" = "16k"
    }
  }

  spec {
    tls {
      hosts       = ["api.example.com"]
      secret_name = "api-tls-cert"
    }

    rule {
      host = "api.example.com"
      http {
        path {
          path = "/"
          path_type = "Prefix"
          backend {
            service {
              name = "api-gateway"
              port {
                number = 80
              }
            }
          }
        }
      }
    }
  }

  depends_on = [
    kubernetes_manifest.cluster_issuer_prod,
    helm_release.ingress_nginx
  ]
}

# Create a LoadBalancer service to expose the ingress controller
resource "kubernetes_service" "ingress_gateway" {
  metadata {
    name      = "ingress-gateway"
    namespace = kubernetes_namespace.ingress.metadata[0].name

    annotations = {
      "cloud.google.com/load-balancer-type" = "External"
      "service.beta.kubernetes.io/external-traffic" = "OnlyLocal"
    }
  }

  spec {
    selector = {
      "app.kubernetes.io/name" = "ingress-nginx"
      "app.kubernetes.io/instance" = "ingress-nginx"
      "app.kubernetes.io/component" = "controller"
    }

    port {
      name        = "http"
      port        = 80
      target_port = 80
    }

    port {
      name        = "https"
      port        = 443
      target_port = 443
    }

    type = "LoadBalancer"
  }

  depends_on = [helm_release.ingress_nginx]
}

# Create a Google managed certificate (alternative to cert-manager)
resource "google_compute_managed_ssl_certificate" "default" {
  provider = google-beta
  
  name = "ingress-managed-cert"
  project = var.project_id
  
  managed {
    domains = ["api.example.com"]
  }
}

# Create firewall rule to allow ingress traffic
resource "google_compute_firewall" "ingress_allow" {
  name    = "allow-ingress-controller"
  project = var.project_id
  network = var.network_id

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["gke-${var.cluster_name}"]
  
  description = "Allow ingress traffic to the cluster ingress controller"
}

# Data source to get ingress IP after deployment
data "kubernetes_service" "ingress_nginx" {
  metadata {
    name      = "ingress-nginx-controller"
    namespace = kubernetes_namespace.ingress.metadata[0].name
  }
  
  depends_on = [helm_release.ingress_nginx]
}