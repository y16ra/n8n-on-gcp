variable "project_id" { type = string }
variable "region" { type = string }
variable "service_name" { type = string }
variable "image" { type = string }
variable "service_account_email" { type = string }

variable "public" { type = bool }

# n8n settings
variable "n8n_basic_auth_user" { type = string }
variable "n8n_basic_auth_password_secret_name" { type = string }
variable "n8n_encryption_key_secret_name" { type = string }

# DB settings
variable "db_host" { type = string }
variable "db_port" { type = number }
variable "db_name" { type = string }
variable "db_user" { type = string }
variable "db_password_secret_name" { type = string }

# Resources
variable "concurrency" { type = number }
variable "cpu" { type = string }
variable "memory" { type = string }

# Cloud Storage settings
variable "storage_bucket_name" {
  description = "Cloud Storage bucket name for binary data"
  type        = string
  default     = ""
}

# Optional
variable "webhook_url" {
  type    = string
  default = ""
}
