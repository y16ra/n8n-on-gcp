output "n8n_encryption_key_secret_name" {
  value       = google_secret_manager_secret.n8n_encryption_key.secret_id
  description = "N8N_ENCRYPTION_KEY の Secret 名"
}

output "db_password_secret_name" {
  value       = google_secret_manager_secret.db_password.secret_id
  description = "DB パスワードの Secret 名"
}

output "basic_auth_password_secret_name" {
  value       = google_secret_manager_secret.basic_auth_password.secret_id
  description = "Basic 認証パスワードの Secret 名"
}
