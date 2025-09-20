output "service_account_email" {
  value       = google_service_account.sa.email
  description = "n8n実行用サービスアカウントのメール"
}
