locals {
  # If webhook_url/editor_base_url are not provided, fall back to n8n_public_url
  effective_webhook_url      = var.webhook_url != "" ? var.webhook_url : var.n8n_public_url
  effective_editor_base_url  = var.n8n_editor_base_url != "" ? var.n8n_editor_base_url : var.n8n_public_url

  # Derive host from n8n_public_url if n8n_host is not provided
  derived_host_from_public = var.n8n_public_url != "" ? replace(replace(var.n8n_public_url, "https://", ""), "http://", "") : ""
  effective_host           = var.n8n_host != "" ? var.n8n_host : local.derived_host_from_public
}

resource "google_cloud_run_v2_service" "this" {
  name     = var.service_name
  location = var.region

  ingress = "INGRESS_TRAFFIC_ALL"

  template {
    service_account = var.service_account_email
    timeout         = "900s"

    scaling {
      min_instance_count = 0
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
        for_each = local.effective_host != "" ? [1] : []
        content {
          name  = "N8N_HOST"
          value = local.effective_host
        }
      }
      dynamic "env" {
        for_each = local.effective_editor_base_url != "" ? [1] : []
        content {
          name  = "N8N_EDITOR_BASE_URL"
          value = local.effective_editor_base_url
        }
      }
      dynamic "env" {
        for_each = var.n8n_public_url != "" ? [1] : []
        content {
          name  = "N8N_PUBLIC_URL"
          value = var.n8n_public_url
        }
      }

      dynamic "env" {
        for_each = local.effective_webhook_url != "" ? [1] : []
        content {
          name  = "WEBHOOK_URL"
          value = local.effective_webhook_url
        }
      }

      # バイナリデータストレージ設定
      env {
        name  = "N8N_BINARY_DATA_MODE"
        value = var.storage_bucket_name != "" ? "s3" : "filesystem"
      }

      # Cloud Storage (S3互換) 設定
      dynamic "env" {
        for_each = var.storage_bucket_name != "" ? {
          N8N_BINARY_DATA_S3_ENDPOINT         = "storage.googleapis.com"
          N8N_BINARY_DATA_S3_BUCKET          = var.storage_bucket_name
          N8N_BINARY_DATA_S3_REGION          = var.region
          N8N_BINARY_DATA_S3_FORCE_PATH_STYLE = "true"
        } : {}
        content {
          name  = env.key
          value = env.value
        }
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
