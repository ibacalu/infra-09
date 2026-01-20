variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment name (production, staging, development)"
  type        = string
}

variable "bucket_purpose" {
  description = "Purpose of the bucket (e.g., 'app-data', 'user-uploads', 'static-assets')"
  type        = string
}

variable "bucket_name" {
  description = "Custom bucket name (optional - will be auto-generated if not provided)"
  type        = string
  default     = ""
}

variable "force_destroy" {
  description = "Allow bucket destruction with objects (USE WITH CAUTION in production)"
  type        = bool
  default     = false
}

variable "data_classification" {
  description = "Data classification level (Public, Internal, Confidential, Restricted)"
  type        = string
  default     = "Internal"

  validation {
    condition     = contains(["Public", "Internal", "Confidential", "Restricted"], var.data_classification)
    error_message = "Data classification must be one of: Public, Internal, Confidential, Restricted"
  }
}

variable "versioning_enabled" {
  description = "Enable versioning for bucket"
  type        = bool
  default     = true
}

variable "mfa_delete_enabled" {
  description = "Enable MFA delete for bucket (requires versioning)"
  type        = bool
  default     = false
}

variable "kms_key_id" {
  description = "KMS key ID for SSE-KMS encryption (leave empty for SSE-S3)"
  type        = string
  default     = ""
}

variable "logging_enabled" {
  description = "Enable access logging"
  type        = bool
  default     = true
}

variable "logging_bucket_name" {
  description = "Bucket name for access logs"
  type        = string
  default     = ""
}

variable "lifecycle_rules_enabled" {
  description = "Enable lifecycle rules"
  type        = bool
  default     = true
}

variable "noncurrent_version_expiration_days" {
  description = "Number of days after which to delete non-current versions (when versioning is enabled)"
  type        = number
  default     = 90
}

variable "transition_rules" {
  description = "Lifecycle transition rules"
  type = list(object({
    id     = string
    status = string
    prefix = string
    transitions = list(object({
      days          = number
      storage_class = string
    }))
    expiration_days = number
  }))
  default = []
}

variable "cors_enabled" {
  description = "Enable CORS configuration"
  type        = bool
  default     = false
}

variable "cors_rules" {
  description = "CORS rules configuration"
  type = list(object({
    allowed_headers = list(string)
    allowed_methods = list(string)
    allowed_origins = list(string)
    expose_headers  = list(string)
    max_age_seconds = number
  }))
  default = []
}

variable "additional_policy_statements" {
  description = "Additional bucket policy statements (for IAM principal access)"
  type        = list(any)
  default     = []
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}