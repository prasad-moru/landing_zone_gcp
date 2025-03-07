# Create namespace for Vault
resource "kubernetes_namespace" "vault" {
  metadata {
    name = "vault"
    
    labels = {
      "app.kubernetes.io/name" = "vault"
      "app.kubernetes.io/instance" = "vault"
    }
  }
}

# Create a Cloud SQL PostgreSQL instance for Vault backend
resource "google_sql_database_instance" "vault_postgres" {
  name             = "vault-postgres-${random_id.db_name_suffix.hex}"
  database_version = "POSTGRES_14"
  region           = var.region
  project          = var.project_id

  settings {
    tier              = var.postgres_tier
    availability_type = var.postgres_ha ? "REGIONAL" : "ZONAL"
    
    disk_size         = 50
    disk_type         = "PD_SSD"
    
    backup_configuration {
      enabled                        = true
      start_time                     = "03:00"
      point_in_time_recovery_enabled = true
      transaction_log_retention_days = 7
      backup_retention_settings {
        retained_backups = 7
        retention_unit   = "COUNT"
      }
    }

    maintenance_window {
      day          = 7  # Sunday
      hour         = 3
      update_track = "stable"
    }

    ip_configuration {
      ipv4_enabled    = false
      private_network = var.network_id
      require_ssl     = true
    }

    insights_config {
      query_insights_enabled  = true
      query_string_length     = 1024
      record_application_tags = true
      record_client_address   = true
    }

    database_flags {
      name  = "max_connections"
      value = "500"
    }
    
    database_flags {
      name  = "log_connections"
      value = "on"
    }

    database_flags {
      name  = "log_disconnections"
      value = "on"
    }
  }

  deletion_protection = false  # Set to true for production
}

# Create a random suffix for the database instance name
resource "random_id" "db_name_suffix" {
  byte_length = 4
}

# Create database for Vault
resource "google_sql_database" "vault_db" {
  name     = "vault"
  instance = google_sql_database_instance.vault_postgres.name
  project  = var.project_id
}

# Create database user for Vault
resource "google_sql_user" "vault_user" {
  name     = "vault"
  instance = google_sql_database_instance.vault_postgres.name
  password = random_password.vault_db_password.result
  project  = var.project_id
}

# Generate random password for Vault database user
resource "random_password" "vault_db_password" {
  length           = 24
  special          = true
  override_special = "_%@"
}

# Create KMS key ring for auto-unsealing Vault
resource "google_kms_key_ring" "vault" {
  name     = "vault-key-ring"
  location = var.region
  project  = var.project_id
}

# Create KMS encryption key for auto-unsealing Vault
resource "google_kms_crypto_key" "vault" {
  name     = "vault-key"
  key_ring = google_kms_key_ring.vault.id
  purpose  = "ENCRYPT_DECRYPT"

  version_template {
    algorithm        = "GOOGLE_SYMMETRIC_ENCRYPTION"
    protection_level = "SOFTWARE"
  }

  rotation_period = "7776000s"  # 90 days
}

# Create service account for Vault
resource "google_service_account" "vault_sa" {
  account_id   = "vault-sa"
  display_name = "Vault Service Account"
  project      = var.project_id
}

# Grant KMS permissions to service account
resource "google_kms_crypto_key_iam_binding" "vault_sa_crypto_key" {
  crypto_key_id = google_kms_crypto_key.vault.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  members       = ["serviceAccount:${google_service_account.vault_sa.email}"]
}

# Create Kubernetes service account for Vault
resource "kubernetes_service_account" "vault" {
  metadata {
    name      = "vault"
    namespace = kubernetes_namespace.vault.metadata[0].name
    annotations = {
      "iam.gke.io/gcp-service-account" = google_service_account.vault_sa.email
    }
  }
}

# Create workload identity binding
resource "google_service_account_iam_binding" "vault_sa_workload_identity" {
  service_account_id = google_service_account.vault_sa.name
  role               = "roles/iam.workloadIdentityUser"
  members = [
    "serviceAccount:${var.project_id}.svc.id.goog[${kubernetes_namespace.vault.metadata[0].name}/${kubernetes_service_account.vault.metadata[0].name}]"
  ]
}

# Create secret for Vault database credentials
resource "kubernetes_secret" "vault_db_creds" {
  metadata {
    name      = "vault-db-creds"
    namespace = kubernetes_namespace.vault.metadata[0].name
  }

  data = {
    "username" = google_sql_user.vault_user.name
    "password" = random_password.vault_db_password.result
  }
}

# Create configmap for Vault configuration
resource "kubernetes_config_map" "vault_config" {
  metadata {
    name      = "vault-config"
    namespace = kubernetes_namespace.vault.metadata[0].name
  }

  data = {
    "vault-config.json" = jsonencode({
      ui                 = true
      disable_clustering = false
      
      listener = {
        tcp = {
          address         = "[::]:8200"
          tls_disable     = 1  # Disable TLS for internal cluster communication
        }
      }
      
      storage = {
        postgresql = {
          connection_url    = "postgres://${google_sql_user.vault_user.name}:${random_password.vault_db_password.result}@${google_sql_database_instance.vault_postgres.private_ip_address}:5432/${google_sql_database.vault_db.name}?sslmode=require"
          table             = "vault"
          max_parallel      = 20
        }
      }
      
      seal = {
        gcpckms = {
          project    = var.project_id
          region     = var.region
          key_ring   = google_kms_key_ring.vault.name
          crypto_key = google_kms_crypto_key.vault.name
        }
      }
      
      telemetry = {
        prometheus_retention_time = "30s"
        disable_hostname          = true
      }
    })
  }
}

# Deploy Vault using Helm
resource "helm_release" "vault" {
  name       = "vault"
  repository = "https://helm.releases.hashicorp.com"
  chart      = "vault"
  version    = "0.22.0"
  namespace  = kubernetes_namespace.vault.metadata[0].name
  timeout    = 900

  values = [
    jsonencode({
      global = {
        enabled = true
        tlsDisable = true
      }
      
      injector = {
        enabled = true
        replicas = 2
        resources = {
          requests = {
            memory = "50Mi"
            cpu = "50m"
          }
          limits = {
            memory = "128Mi"
            cpu = "250m"
          }
        }
      }
      
      server = {
        image = {
          repository = "hashicorp/vault"
          tag        = "1.12.0"
        }
        
        updateStrategyType = "RollingUpdate"
        
        resources = {
          requests = {
            memory = "256Mi"
            cpu = "250m"
          }
          limits = {
            memory = "512Mi"
            cpu = "500m"
          }
        }
        
        ha = {
          enabled = true
          replicas = 3
          
          raft = {
            enabled = false  # Using PostgreSQL instead
          }
        }
        
        dataStorage = {
          enabled = true
          size = "10Gi"
          storageClass = "standard-ssd"
        }
        
        auditStorage = {
          enabled = true
          size = "10Gi"
          storageClass = "standard-ssd"
        }
        
        serviceAccount = {
          create = false
          name = kubernetes_service_account.vault.metadata[0].name
        }
        
        extraSecretEnvironmentVars = [
          {
            envName = "GOOGLE_PROJECT"
            secretName = "vault-sa-key"
            secretKey = "project_id"
          }
        ]
        
        extraEnvironmentVars = {
          GOOGLE_REGION = var.region
          VAULT_CACERT = "/vault/userconfig/vault-ca/ca.crt"
        }
        
        volumes = [
          {
            name = "vault-config"
            configMap = {
              name = kubernetes_config_map.vault_config.metadata[0].name
            }
          },
          {
            name = "vault-db-creds"
            secret = {
              secretName = kubernetes_secret.vault_db_creds.metadata[0].name
            }
          }
        ]
        
        volumeMounts = [
          {
            name = "vault-config"
            mountPath = "/vault/config"
          },
          {
            name = "vault-db-creds"
            mountPath = "/vault/db-creds"
            readOnly = true
          }
        ]
        
        extraArgs = "-config=/vault/config/vault-config.json"
        
        # Configure readiness/liveness probes
        readinessProbe = {
          enabled = true
          path = "/v1/sys/health?standbyok=true"
        }
        
        livenessProbe = {
          enabled = true
          path = "/v1/sys/health?standbyok=true"
          initialDelaySeconds = 60
        }
        
        # Service configuration for accessing Vault
        service = {
          enabled = true
          type = "ClusterIP"
          port = 8200
          targetPort = 8200
        }
        
        # Configure Ingress for external access
        ingress = {
          enabled = true
          annotations = {
            "kubernetes.io/ingress.class" = "nginx"
            "cert-manager.io/cluster-issuer" = "letsencrypt-prod"
          }
          hosts = [
            {
              host = "vault.example.com"
              paths = ["/"]
            }
          ]
          tls = [
            {
              secretName = "vault-tls"
              hosts = ["vault.example.com"]
            }
          ]
        }
      }
      
      ui = {
        enabled = true
        serviceType = "ClusterIP"
        serviceNodePort = null
        externalPort = 8200
      }
    })
  ]

  depends_on = [
    kubernetes_config_map.vault_config,
    kubernetes_secret.vault_db_creds,
    google_sql_database_instance.vault_postgres
  ]
}

# Configure Vault initialization and setup
resource "null_resource" "vault_setup" {
  triggers = {
    helm_release = helm_release.vault.id
  }

  provisioner "local-exec" {
    command = <<-EOF
      #!/bin/bash
      set -e
      
      # Wait for Vault to be ready
      echo "Waiting for Vault to be ready..."
      kubectl wait --for=condition=Ready pods -l app.kubernetes.io/name=vault --namespace ${kubernetes_namespace.vault.metadata[0].name} --timeout=300s
      
      # Initialize Vault (only if not already initialized)
      INIT_STATUS=$(kubectl exec -ti vault-0 -n ${kubernetes_namespace.vault.metadata[0].name} -- vault status -format=json 2>/dev/null || echo '{"initialized": false}')
      INITIALIZED=$(echo $INIT_STATUS | jq -r '.initialized')
      
      if [ "$INITIALIZED" == "false" ]; then
        echo "Initializing Vault..."
        kubectl exec -ti vault-0 -n ${kubernetes_namespace.vault.metadata[0].name} -- vault operator init -key-shares=5 -key-threshold=3 -format=json > vault-init.json
        
        # Save the init data to a Kubernetes secret
        kubectl create secret generic vault-init -n ${kubernetes_namespace.vault.metadata[0].name} --from-file=vault-init.json
        
        echo "Vault initialized successfully. Root token and unseal keys saved to vault-init secret."
      else
        echo "Vault is already initialized."
      fi
    EOF
  }

  depends_on = [
    helm_release.vault
  ]
}

# Create services to expose Vault for microservices
resource "kubernetes_service" "vault_internal" {
  metadata {
    name      = "vault-internal"
    namespace = kubernetes_namespace.vault.metadata[0].name
    
    annotations = {
      "cloud.google.com/neg" = "{\"ingress\": true}"
    }
  }
  
  spec {
    selector = {
      "app.kubernetes.io/name" = "vault"
      "component" = "server"
    }
    
    port {
      name        = "http"
      port        = 8200
      target_port = 8200
    }
    
    type = "ClusterIP"
  }
  
  depends_on = [
    helm_release.vault
  ]
}