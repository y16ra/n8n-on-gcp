variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "region" {
  description = "The GCP region"
  type        = string
}

variable "repository_id" {
  description = "The artifact registry repository ID"
  type        = string
}

variable "description" {
  description = "Description for the artifact registry repository"
  type        = string
  default     = "Docker registry for n8n images"
}