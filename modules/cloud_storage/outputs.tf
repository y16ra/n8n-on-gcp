output "bucket_name" {
  description = "Name of the created Cloud Storage bucket"
  value       = google_storage_bucket.n8n_binary_data.name
}

output "bucket_url" {
  description = "URL of the created Cloud Storage bucket"
  value       = google_storage_bucket.n8n_binary_data.url
}