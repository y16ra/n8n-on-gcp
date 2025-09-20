output "service_url" {
  value       = module.cloud_run_n8n.service_url
  description = "Cloud Run n8n サービスのURL"
}

output "image_repository" {
  value       = module.artifact_registry.repository_url
  description = "Artifact Registry リポジトリURL (…-docker.pkg.dev/PROJECT/REPO)"
}

output "image_ref" {
  value       = "${module.artifact_registry.repository_url}/n8n:${var.image_tag}"
  description = "デプロイに使用したイメージの参照"
}
