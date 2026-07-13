variable "project" {
  description = "Project slug used as resource prefix."
  type        = string
  default     = "wapa"
}

variable "environment" {
  description = "Environment slug."
  type        = string
  default     = "prod"
}

variable "domain_name" {
  description = "Public domain for the API (e.g. api.wapaexchange.com)."
  type        = string
}

variable "acm_certificate_arn" {
  description = "Pre-issued ACM cert ARN for the ALB listener."
  type        = string
}

variable "db_password" {
  description = "Master password for RDS. Pass via tfvars or env var, never commit."
  type        = string
  sensitive   = true
}

variable "container_image" {
  description = "ECR image URI for the API + worker, e.g. 123.dkr.ecr.eu-west-3.amazonaws.com/wapaexchange:tag"
  type        = string
}

variable "cors_origin" {
  description = "Comma-separated list of allowed origins for browser clients (e.g. https://admin.wapaexchange.com,https://wapaexchange.com)."
  type        = string
}
