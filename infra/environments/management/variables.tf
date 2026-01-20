# Management Account Variables
# Core configuration variables for the AWS Organizations management account

variable "aws_region" {
  description = "AWS region for management account resources"
  type        = string
  default     = "eu-central-1"
}

variable "project_name" {
  description = "Name of the project for resource naming and tagging"
  type        = string
}

variable "organization_name" {
  description = "Name of the AWS Organization"
  type        = string
}

variable "owner_team" {
  description = "Team responsible for this infrastructure"
  type        = string
}

variable "cost_center" {
  description = "Cost center for billing allocation"
  type        = string
}

variable "security_account_email" {
  description = "Email address for the security account"
  type        = string
}

variable "production_account_email" {
  description = "Email address for the production account"
  type        = string
}

variable "enable_config" {
  description = "Enable AWS Config for compliance monitoring"
  type        = bool
  default     = true
}

variable "enable_cloudtrail" {
  description = "Enable CloudTrail for audit logging"
  type        = bool
  default     = true
}

variable "enable_guardduty" {
  description = "Enable GuardDuty for threat detection"
  type        = bool
  default     = true
}

# IAM Identity Center (SSO) Configuration
variable "admin_user_email" {
  description = "Email address for the initial admin user in IAM Identity Center"
  type        = string
  default     = null
}

variable "enable_identity_center_mfa" {
  description = "Enable multi-factor authentication for all Identity Center users"
  type        = bool
  default     = true
}

variable "identity_center_session_duration_admin" {
  description = "Session duration for admin access in IAM Identity Center (ISO 8601 format)"
  type        = string
  default     = "PT4H" # 4 hours
}

variable "identity_center_session_duration_developer" {
  description = "Session duration for developer access in IAM Identity Center (ISO 8601 format)"
  type        = string
  default     = "PT8H" # 8 hours
}

variable "users" {
  description = "Map of users to create in Identity Center"
  type = map(object({
    email      = string
    first_name = string
    last_name  = string
    groups     = list(string)
  }))
  default = {}
}

variable "tfc_organization" {
  description = "Terraform Cloud organization name for OIDC authentication"
  type        = string
}
