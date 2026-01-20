# AWS IAM Identity Center Module Variables

variable "project_name" {
  description = "Name of the project for resource naming and tagging"
  type        = string
}

variable "common_tags" {
  description = "Common tags to be applied to all resources"
  type        = map(string)
  default     = {}
}

variable "management_account_id" {
  description = "AWS Management Account ID"
  type        = string
  default     = null
}

variable "production_account_id" {
  description = "AWS Production Account ID"
  type        = string
  default     = null
}

variable "security_account_id" {
  description = "AWS Security Account ID (current account)"
  type        = string
  default     = null
}

variable "admin_user_email" {
  description = "Email address for the initial admin user"
  type        = string
  default     = null
}

variable "enable_mfa" {
  description = "Enable multi-factor authentication for all users"
  type        = bool
  default     = true
}

variable "session_duration_admin" {
  description = "Session duration for admin access (in ISO 8601 format)"
  type        = string
  default     = "PT4H" # 4 hours
}

variable "session_duration_developer" {
  description = "Session duration for developer access (in ISO 8601 format)"
  type        = string
  default     = "PT8H" # 8 hours
}

variable "users" {
  description = "Map of users to create in Identity Center"
  type = map(object({
    email      = string
    first_name = string
    last_name  = string
    groups     = list(string) # Valid: "administrators", "developers", "viewers"
  }))
  default = {}
}
