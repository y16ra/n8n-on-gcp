variable "project_id" { type = string }

variable "services" {
  type        = list(string)
  description = "有効化するGCP API サービス一覧"
  default = [
    "run.googleapis.com",
    "artifactregistry.googleapis.com",
    "secretmanager.googleapis.com",
    "cloudbuild.googleapis.com",
  ]
}
