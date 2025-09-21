resource "google_storage_bucket" "n8n_binary_data" {
  name     = var.bucket_name
  location = var.region

  # バージョニングを有効化
  versioning {
    enabled = var.versioning_enabled
  }

  # ライフサイクル管理
  dynamic "lifecycle_rule" {
    for_each = var.lifecycle_rules
    content {
      condition {
        age = lifecycle_rule.value.age
      }
      action {
        type = lifecycle_rule.value.action
      }
    }
  }

  # CORS設定（必要に応じて）
  dynamic "cors" {
    for_each = var.cors_enabled ? [1] : []
    content {
      origin          = var.cors_origins
      method          = ["GET", "HEAD", "PUT", "POST", "DELETE"]
      response_header = ["*"]
      max_age_seconds = 3600
    }
  }

  # 均等アクセス制御
  uniform_bucket_level_access = true

  # 公開アクセス防止
  public_access_prevention = "enforced"
}

# Service Accountにバケットアクセス権限を付与
resource "google_storage_bucket_iam_member" "n8n_binary_data_access" {
  bucket = google_storage_bucket.n8n_binary_data.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${var.service_account_email}"
}