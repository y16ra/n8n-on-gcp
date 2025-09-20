variable "project_id" { type = string }
variable "service_account_email" { type = string }

variable "n8n_encryption_key_secret_name" {
  type    = string
  default = "n8n-encryption-key"
}

variable "db_password_secret_name" {
  type    = string
  default = "n8n-db-password"
}

variable "basic_auth_password_secret_name" {
  type    = string
  default = "n8n-basic-auth-password"
}
