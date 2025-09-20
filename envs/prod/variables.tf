variable "project_id" { type = string }

variable "region" {
  type    = string
  default = "asia-northeast1"
}

variable "service_name" {
  type    = string
  default = "n8n"
}

variable "repository_id" {
  type    = string
  default = "n8n"
}

variable "image_tag" {
  type    = string
  description = "n8n コンテナのタグ（例: 1.63.0, latest）"
  default = "latest"
}

variable "public" {
  type    = bool
  description = "Cloud Run を未認証公開にするか（Basic Auth 併用推奨）"
  default = true
}

variable "n8n_basic_auth_user" {
  type        = string
  description = "n8nのBasic認証ユーザー名"
}

variable "n8n_basic_auth_password_secret_name" {
  type        = string
  default     = "n8n-basic-auth-password"
  description = "Basic認証パスワードを保存するSecret名"
}

variable "n8n_encryption_key_secret_name" {
  type        = string
  default     = "n8n-encryption-key"
  description = "N8N_ENCRYPTION_KEYを保存するSecret名"
}

variable "db_password_secret_name" {
  type        = string
  default     = "n8n-db-password"
  description = "DBパスワードを保存するSecret名"
}

variable "db_host" { type = string }
variable "db_name" { type = string }
variable "db_user" { type = string }

variable "db_port" {
  type    = number
  default = 5432
}

variable "webhook_url" {
  type        = string
  default     = ""
  description = "必要に応じて設定。未設定の場合は未指定運用（後から再適用可）"
}

variable "concurrency" {
  type    = number
  default = 10
}

variable "cpu" {
  type    = string
  default = "1"
}

variable "memory" {
  type    = string
  default = "1Gi"
}

# Cloud Storage settings
variable "storage_versioning_enabled" {
  type        = bool
  default     = false
  description = "Cloud Storageバケットのバージョニングを有効にするか"
}

variable "storage_lifecycle_rules" {
  type = list(object({
    age    = number
    action = string
  }))
  default = [
    {
      age    = 90
      action = "Delete"
    }
  ]
  description = "Cloud Storageのライフサイクルルール"
}
