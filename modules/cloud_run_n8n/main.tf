resource "google_cloud_run_v2_service" "this" {
  name     = var.service_name
  location = var.region

  ingress = "INGRESS_TRAFFIC_ALL"

  template {
    service_account = var.service_account_email
    timeout         = "900s"

    scaling {
      min_instance_count = 1
      max_instance_count = 1
    }

    containers {
      image = var.image

      ports {
        name           = "http1"
        container_port = 8080
      }

      resources {
        limits = {
          cpu    = var.cpu
          memory = var.memory
        }
      }

      # --- n8n security ---
      env {
        name  = "N8N_BASIC_AUTH_ACTIVE"
        value = "true"
      }
      env {
        name  = "N8N_BASIC_AUTH_USER"
        value = var.n8n_basic_auth_user
      }
      env {
        name = "N8N_BASIC_AUTH_PASSWORD"
        value_source {
          secret_key_ref {
            secret  = var.n8n_basic_auth_password_secret_name
            version = "latest"
          }
        }
      }
      env {
        name = "N8N_ENCRYPTION_KEY"
        value_source {
          secret_key_ref {
            secret  = var.n8n_encryption_key_secret_name
            version = "latest"
          }
        }
      }

      # --- n8n DB ---
      env {
        name  = "DB_TYPE"
        value = "postgresdb"
      }
      env {
        name  = "DB_POSTGRESDB_HOST"
        value = var.db_host
      }
      env {
        name  = "DB_POSTGRESDB_PORT"
        value = tostring(var.db_port)
      }
      env {
        name  = "DB_POSTGRESDB_DATABASE"
        value = var.db_name
      }
      env {
        name  = "DB_POSTGRESDB_USER"
        value = var.db_user
      }
      env {
        name = "DB_POSTGRESDB_PASSWORD"
        value_source {
          secret_key_ref {
            secret  = var.db_password_secret_name
            version = "latest"
          }
        }
      }
      env {
        name  = "DB_POSTGRESDB_SSL"
        value = "true"
      }
      env {
        name  = "DB_POSTGRESDB_SSL_REJECT_UNAUTHORIZED"
        value = "false"
      }
      env {
        name  = "DB_POSTGRESDB_CONNECTION_TIMEOUT"
        value = "60000"
      }

      # --- n8n runtime ---
      env {
        name  = "N8N_PORT"
        value = "8080"
      }
      env {
        name  = "N8N_PROTOCOL"
        value = "https"
      }

      dynamic "env" {
        for_each = var.webhook_url != "" ? [1] : []
        content {
          name  = "WEBHOOK_URL"
          value = var.webhook_url
        }
      }

      # バイナリは最小構成ではfilesystem
      env {
        name  = "N8N_BINARY_DATA_MODE"
        value = "filesystem"
      }

    }

    # Cloud Run uses PORT env automatically; 8080 is default in container
  }

  traffic {
    percent = 100
    type    = "TRAFFIC_TARGET_ALLOCATION_TYPE_LATEST"
  }
}

# 未認証アクセスを許可（Basic Authが前提）
resource "google_cloud_run_v2_service_iam_member" "public" {
  count    = var.public ? 1 : 0
  location = var.region
  name     = google_cloud_run_v2_service.this.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}

output "service_url" {
  value = google_cloud_run_v2_service.this.uri
}
