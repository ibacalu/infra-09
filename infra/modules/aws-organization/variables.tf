# AWS Organizations Module Variables

variable "project_name" {
  description = "Name of the project for resource naming and tagging"
  type        = string
}

variable "organization_name" {
  description = "Name of the AWS Organization"
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

variable "common_tags" {
  description = "Common tags to be applied to all resources"
  type        = map(string)
  default     = {}
}