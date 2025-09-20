module "gcp_services" {
  source     = "../../modules/gcp_services"
  project_id = var.project_id
  services = [
    "run.googleapis.com",
    "artifactregistry.googleapis.com",
    "secretmanager.googleapis.com",
    "cloudbuild.googleapis.com",
  ]
}

module "artifact_registry" {
  source        = "../../modules/artifact_registry"
  project_id    = var.project_id
  region        = var.region
  repository_id = var.repository_id
  depends_on    = [module.gcp_services]
}

module "iam" {
  source             = "../../modules/iam"
  project_id         = var.project_id
  service_account_id = "n8n-sa"
  display_name       = "n8n service account"
  depends_on         = [module.gcp_services]
}

module "secrets" {
  source                        = "../../modules/secrets"
  project_id                    = var.project_id
  service_account_email         = module.iam.service_account_email
  n8n_encryption_key_secret_name = var.n8n_encryption_key_secret_name
  db_password_secret_name        = var.db_password_secret_name
  basic_auth_password_secret_name = var.n8n_basic_auth_password_secret_name
  depends_on                     = [module.gcp_services]
}

locals {
  image_repository = "${module.artifact_registry.repository_url}/n8n"
  image            = "${local.image_repository}:${var.image_tag}"
}

module "cloud_run_n8n" {
  source                = "../../modules/cloud_run_n8n"
  project_id            = var.project_id
  region                = var.region
  service_name          = var.service_name
  image                 = local.image
  service_account_email = module.iam.service_account_email
  public                = var.public

  # n8n
  n8n_basic_auth_user                 = var.n8n_basic_auth_user
  n8n_basic_auth_password_secret_name = var.n8n_basic_auth_password_secret_name
  n8n_encryption_key_secret_name      = var.n8n_encryption_key_secret_name

  # DB (Supabase)
  db_host                 = var.db_host
  db_port                 = var.db_port
  db_name                 = var.db_name
  db_user                 = var.db_user
  db_password_secret_name = var.db_password_secret_name

  # Runtime
  concurrency = var.concurrency
  cpu         = var.cpu
  memory      = var.memory
  webhook_url = var.webhook_url
  depends_on  = [module.gcp_services]
}
