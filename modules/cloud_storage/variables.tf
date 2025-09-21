variable "bucket_name" {
  description = "Name of the Cloud Storage bucket for n8n binary data"
  type        = string
}

variable "region" {
  description = "Region for the Cloud Storage bucket"
  type        = string
}

variable "service_account_email" {
  description = "Service account email that needs access to the bucket"
  type        = string
}

variable "versioning_enabled" {
  description = "Enable versioning for the bucket"
  type        = bool
  default     = false
}

variable "lifecycle_rules" {
  description = "Lifecycle rules for the bucket"
  type = list(object({
    age    = number
    action = string
  }))
  default = [
    {
      age    = 90
      action = "Delete"
    }
  ]
}

variable "cors_enabled" {
  description = "Enable CORS for the bucket"
  type        = bool
  default     = false
}

variable "cors_origins" {
  description = "CORS allowed origins"
  type        = list(string)
  default     = ["*"]
}