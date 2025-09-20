resource "google_secret_manager_secret" "n8n_encryption_key" {
  project   = var.project_id
  secret_id = var.n8n_encryption_key_secret_name
  replication {
    auto {}
  }
}

resource "google_secret_manager_secret" "db_password" {
  project   = var.project_id
  secret_id = var.db_password_secret_name
  replication {
    auto {}
  }
}

resource "google_secret_manager_secret" "basic_auth_password" {
  project   = var.project_id
  secret_id = var.basic_auth_password_secret_name
  replication {
    auto {}
  }
}

# SA に Secret の読み取り権限を付与
resource "google_secret_manager_secret_iam_member" "enc_key_accessor" {
  project   = var.project_id
  secret_id = google_secret_manager_secret.n8n_encryption_key.secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${var.service_account_email}"
}

resource "google_secret_manager_secret_iam_member" "db_pw_accessor" {
  project   = var.project_id
  secret_id = google_secret_manager_secret.db_password.secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${var.service_account_email}"
}

resource "google_secret_manager_secret_iam_member" "basic_auth_pw_accessor" {
  project   = var.project_id
  secret_id = google_secret_manager_secret.basic_auth_password.secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${var.service_account_email}"
}
