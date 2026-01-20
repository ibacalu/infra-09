# Account Baseline Module Variables

variable "account_name" {
  description = "Name of the AWS account (e.g., management, security, production)"
  type        = string
}

variable "environment" {
  description = "Environment name (should match account_name for consistency)"
  type        = string
}

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
  description = "Management account ID for cross-account role trust relationships"
  type        = string
  default     = null
}

variable "enable_cloudtrail" {
  description = "Enable CloudTrail for audit logging"
  type        = bool
  default     = true
}

variable "enable_config" {
  description = "Enable AWS Config for compliance monitoring"
  type        = bool
  default     = true
}

variable "enable_guardduty" {
  description = "Enable GuardDuty for threat detection"
  type        = bool
  default     = false
}